# frozen_string_literal: true

module Gitlab
  module PrinciplesDistiller
    class Sync
      # Duo Workflow API client + polling + diagnostics. Shared across
      # all parallel_distill threads; the memoized `||=` readers are safe
      # under sharing because each computes a deterministic value from ENV.
      # Any new shared mutable state needs its own Mutex.
      class Workflow
        DEFAULT_GITLAB_HOST = 'https://gitlab.com'

        # Polling cadence is coarse (every 10s) to limit GraphQL request
        # volume; timeout accounts for runner queue + cold image pull plus
        # the actual distillation time.
        POLL_INTERVAL_SECONDS = 10
        POLL_TIMEOUT_SECONDS  = 1500
        TERMINAL_STATES       = %w[FINISHED FAILED STOPPED].freeze

        # Tolerance for short-window read-after-write inconsistencies on the
        # GraphQL read path: freshly-created workflows can briefly return
        # "Workflow not found", and a FINISHED workflow's agent message can
        # arrive a beat after the status flips. Both clear quickly; consuming
        # a full per-principle retry (5+ min backoff) for these would waste
        # wall-clock time. NODE_LOOKUP_GRACE_POLLS / FINISHED_CONTENT_GRACE_POLLS
        # are the number of POLL_INTERVAL_SECONDS waits we tolerate before
        # declaring the workflow genuinely missing or genuinely incomplete.
        NODE_LOOKUP_GRACE_POLLS = 6 # ~60s grace for indexing lag
        FINISHED_CONTENT_GRACE_POLLS = 6 # ~60s grace for message propagation

        def initialize(manifest:)
          @manifest = manifest
        end

        attr_reader :manifest

        def gitlab_host
          @gitlab_host ||= ENV.fetch(Env::GITLAB_HOST, DEFAULT_GITLAB_HOST).chomp('/')
        end

        def catalog_project_path
          @catalog_project_path ||= ENV.fetch(Env::CATALOG_PROJECT) do
            abort Rainbow("ERROR: #{Env::CATALOG_PROJECT} env var is required").red
          end
        end

        def default_branch
          @default_branch ||= ENV.fetch(Env::CI_DEFAULT_BRANCH) do
            abort Rainbow("ERROR: #{Env::CI_DEFAULT_BRANCH} env var is required").red
          end
        end

        def post_json(url, headers: {}, body: {})
          json_request(Net::HTTP::Post, url, headers: headers, body: body)
        end

        def put_json(url, headers: {}, body: {})
          json_request(Net::HTTP::Put, url, headers: headers, body: body)
        end

        # Returns the agent's final content for one principle, or nil on
        # failure (caller handles retries).
        #
        # The agent runs server-side in a child CI pipeline and reads the
        # distilled file + SSOT sources directly from source_branch via
        # gitaly. We do NOT inline file contents in the request body to
        # avoid argv/header limits.
        def distill(name, config)
          goal = build_goal(name, config)
          additional_context = build_additional_context(name, config)

          workflow_id = start(goal: goal, additional_context: additional_context, principle: name)
          return unless workflow_id

          poll(workflow_id, principle: name)
        end

        def build_goal(name, config)
          sources = config.fetch('sources', []).map { |s| "- #{s['path']}" }.join("\n")
          baseline_line = config['baseline'] ? "- #{config['baseline']}" : '(none)'
          distilled_path = manifest.principles_path(name)

          <<~GOAL
            Distill the GitLab development principle "#{name}".

            Read these files using the read_files tool, then produce the complete
            updated checklist file (start your response with "# <Title> Principles")
            following the rules in your system prompt.

            First reconcile the prior checklist against the SSOT (system prompt
            rule 16): read each SSOT source file in full, ADD checklist items for
            genuinely new SSOT content (new sections, rules, tooling,
            enforcement), REVISE any item whose SSOT guidance changed (including
            new enforcement for behavior an existing item already mandates — fold
            it into that item, do not add a duplicate), and DROP an item ONLY when
            you confirm its rule is absent from the FULL SSOT sources (grep them).
            NEVER drop an item just because it is missing from a diff — keep it
            when unsure (system prompt rule 16c). But if a prior item's topic is
            wholly absent from the full SSOT sources (confirmed by grep), DROP it
            even if it looks useful — it belongs to another principle's SSOT
            (system prompt rule 16d). Likewise, DO NOT emit a standalone bullet
            for an SSOT mapping row that only delegates detail to another guide
            or is already covered by a generic rule you emit (rule 16d). Then
            apply the imperative-mood
            rule to every item. Do not simply re-emit the prior checklist. Keep
            all other lines untouched (system prompt rule 18).

            Current distilled file (the PRIOR version — reconcile it against the
            SSOT, do not assume it is still complete or correct):
            - #{distilled_path}

            SSOT source files (the documentation to distill from):
            #{sources}

            Baseline (include verbatim, exempt from rephrasing):
            #{baseline_line}

            Output ONLY the checklist content. No preamble, no thinking, no
            trailing notes.
          GOAL
        end

        def build_additional_context(name, config)
          payload = {
            principle: name,
            distilled_path: manifest.principles_path(name),
            sources: config.fetch('sources', []).map { |s| s.slice('path', 'url') },
            baseline_path: config['baseline']
          }

          [{ Category: 'agent_principles_distillation', Content: payload.to_json }]
        end

        # Dumps workflow URL, human-readable status, message-type counts,
        # and a preview of the most recent messages to help diagnose whether
        # the agent never spoke, only emitted tool calls, or returned
        # unparseable content.
        def log_failure_details(workflow_id, status, human_status, messages, ever_running)
          url = "#{gitlab_host}/#{catalog_project_path}/-/automate/agent-sessions/#{workflow_id}"

          messages ||= []
          hint = if !ever_running && messages.empty?
                   'workflow never reached RUNNING — likely Gitaly load on partial-clone fetch ' \
                     '(see Known Limitations in .ai/principles/README.md)'
                 elsif ever_running && messages.empty?
                   'workflow reached RUNNING but produced no messages — likely agent crashed during bootstrap'
                 else
                   'workflow reached RUNNING but did not produce parseable content — likely agent-side issue'
                 end

          warn Rainbow("    hint: #{hint}").yellow
          warn Rainbow("    workflow URL: #{url}").faint
          warn Rainbow("    humanStatus: #{human_status.inspect} (statusName: #{status})").faint

          counts = messages.group_by { |m| m['messageType'].to_s }.transform_values(&:size)
          warn Rainbow("    messages by type: #{counts.inspect} (total #{messages.size})").faint

          return if messages.empty?

          warn Rainbow("    last #{[messages.size, 5].min} message(s):").faint
          messages.last(5).each_with_index do |m, i|
            preview = m['content'].to_s.gsub(/\s+/, ' ').strip.slice(0, 500)
            header = "[#{i}] type=#{m['messageType']} role=#{m['role'].inspect} status=#{m['status'].inspect}"
            warn Rainbow("      #{header}").faint
            warn Rainbow("          content: #{preview}").faint
          end
        end

        # DAP messages have `role: null`, so we filter on messageType:
        # 'agent' is the agent's natural-language reply, 'tool' is internal
        # tool-call output we skip.
        def extract_assistant_content(messages)
          return if messages.nil? || messages.empty?

          candidates = messages.select do |m|
            m['messageType'].to_s == 'agent' && !m['content'].to_s.strip.empty?
          end

          candidates.last&.dig('content')
        end

        def validate_config!
          missing = []
          missing << Env::GITLAB_TOKEN if ENV[Env::GITLAB_TOKEN].to_s.empty?
          missing << Env::CATALOG_ITEM_CONSUMER_ID if catalog_item_consumer_id.to_s.empty?

          return if missing.empty?

          abort Rainbow(
            "ERROR: Workflow API is not configured. Missing env: #{missing.join(', ')}.\n" \
              'Run gitlab-ai-principles-distiller-provision-flow first to provision the catalog flow ' \
              'and obtain the consumer ID.'
          ).red
        end

        # Pre-empts late agent failures by verifying every SSOT source
        # file (each `sources[].path` plus the `baseline:`) exists on disk
        # before triggering the workflow. Delegates both the path set and the
        # existence rule (including the `_index.md` fallback) to Manifest so
        # the shift-left Validator and this runtime guard stay in lockstep.
        def validate_sources!(config)
          manifest.config_source_paths(config).each do |path|
            next if manifest.source_file_exists?(path)

            raise "SSOT source file not found: #{path} — " \
              'check that the path in manifest.yml matches an existing file on the current branch'
          end
        end

        # Heartbeats every 60s so CI doesn't mark the job stuck during
        # long backoff waits.
        def sleep_with_heartbeat(seconds, label, log)
          remaining = seconds
          while remaining.positive?
            chunk = [60, remaining].min
            sleep(chunk)
            remaining -= chunk
            log.call(Rainbow("    #{label}: #{remaining}s remaining...").faint) if remaining.positive?
          end
        end

        private

        def catalog_item_consumer_id
          ENV[Env::CATALOG_ITEM_CONSUMER_ID]
        end

        def source_branch
          @source_branch ||= if ENV[Env::CI_COMMIT_REF_NAME].to_s.empty?
                               current_git_branch
                             else
                               ENV[Env::CI_COMMIT_REF_NAME]
                             end
        end

        def graphql_client
          @graphql_client ||= GraphqlClient.new(host: gitlab_host, token: ENV.fetch(Env::GITLAB_TOKEN))
        end

        # Per-principle batch policy: a single failed query is one of many
        # in the polling loop and should be logged + skipped rather than
        # aborting the whole distillation. Contrast ProvisionFlow#graphql.
        def graphql(query, variables = {})
          graphql_client.query(query, variables)
        rescue GraphqlClient::Error => e
          warn Rainbow(e.message).red
          nil
        rescue StandardError => e
          warn Rainbow("GraphQL request failed: #{e.message}").red
          nil
        end

        def start(goal:, additional_context:, principle: nil)
          url = "#{gitlab_host}/api/v4/ai/duo_workflows/workflows"
          body = {
            project_id: catalog_project_path,
            ai_catalog_item_consumer_id: catalog_item_consumer_id.to_i,
            start_workflow: true,
            source_branch: source_branch,
            goal: goal,
            additional_context: additional_context
          }

          response = post_json(url,
            headers: { 'Authorization' => "Bearer #{ENV.fetch(Env::GITLAB_TOKEN)}" },
            body: body)

          unless response.is_a?(Net::HTTPSuccess)
            warn Rainbow("Workflow create failed#{principle ? " for #{principle}" : ''}: " \
              "HTTP #{response.code}: #{response.body.to_s.slice(0, 500)}").red
            return
          end

          workflow = JSON.parse(response.body)
          workflow_id = workflow['id']
          return unless workflow_id

          puts Rainbow("    workflow id=#{workflow_id}#{principle ? " (#{principle})" : ''} " \
            "branch=#{source_branch}").faint
          workflow_id
        rescue StandardError => e
          warn Rainbow("Workflow create error#{principle ? " for #{principle}" : ''}: #{e.message}").red
          nil
        end

        def poll(workflow_id, principle: nil)
          deadline = Time.now.utc + POLL_TIMEOUT_SECONDS
          workflow_gid = "gid://gitlab/Ai::DuoWorkflows::Workflow/#{workflow_id}"
          previous_status = nil
          started_at = Time.now.utc
          ever_running = false
          node_lookup_misses = 0
          tag = workflow_tag(workflow_id, principle)

          while Time.now.utc < deadline
            node = fetch_workflow_node(workflow_gid)
            unless node
              node_lookup_misses += 1
              if node_lookup_misses >= NODE_LOOKUP_GRACE_POLLS
                warn Rainbow("    workflow #{tag} not found via GraphQL " \
                  "after #{node_lookup_misses} polls").yellow
                return
              end

              # Transient lookup miss: the workflow was just created and
              # hasn't propagated to the GraphQL read path yet. Don't
              # alarm in the log; debug-only.
              puts Rainbow("    workflow #{tag} transient lookup miss " \
                "#{node_lookup_misses}/#{NODE_LOOKUP_GRACE_POLLS} " \
                '(not yet indexed)').faint
              sleep(POLL_INTERVAL_SECONDS)
              next
            end

            node_lookup_misses = 0

            status = node['statusName'].to_s.upcase
            ever_running ||= status == 'RUNNING'
            log_progress(workflow_id, status, previous_status, started_at, principle: principle)
            previous_status = status

            if TERMINAL_STATES.include?(status)
              messages = node.dig('latestCheckpoint', 'duoMessages')

              if status == 'FINISHED'
                content = extract_assistant_content(messages)
                content ||= await_finished_content(workflow_gid, workflow_id, principle: principle)
                if content.nil?
                  log_failure_details(workflow_id, status, node['humanStatus'], messages,
                    ever_running)
                end

                return content
              end

              # Non-FINISHED terminal: return nil to trigger the caller's
              # retry. We don't classify transient vs permanent here because
              # most failures are transient (Gitaly load) and the long
              # backoffs accommodate slow remediation either way.
              warn Rainbow("    workflow #{tag} ended with status #{status}").yellow
              log_failure_details(workflow_id, status, node['humanStatus'], messages, ever_running)
              return
            end

            sleep(POLL_INTERVAL_SECONDS)
          end

          warn Rainbow("    workflow #{tag} timed out after #{POLL_TIMEOUT_SECONDS}s").yellow
          nil
        end

        # FINISHED can land on the status field a beat before the final agent
        # message lands in latestCheckpoint.duoMessages. Re-poll for up to
        # FINISHED_CONTENT_GRACE_POLLS to give the agent reply time to
        # propagate; without this we'd consume a full per-principle retry
        # (with its 5-30min backoff) for what is really a short consistency
        # delay.
        def await_finished_content(workflow_gid, workflow_id, principle: nil)
          tag = workflow_tag(workflow_id, principle)
          FINISHED_CONTENT_GRACE_POLLS.times do |i|
            sleep(POLL_INTERVAL_SECONDS)
            node = fetch_workflow_node(workflow_gid)
            next unless node

            messages = node.dig('latestCheckpoint', 'duoMessages')
            content = extract_assistant_content(messages)
            next unless content

            puts Rainbow("    workflow #{tag} agent content appeared on " \
              "grace poll #{i + 1}/#{FINISHED_CONTENT_GRACE_POLLS}").faint
            return content
          end

          nil
        end

        def fetch_workflow_node(workflow_gid)
          data = graphql(<<~GQL, { id: workflow_gid })
            query GetWorkflow($id: AiDuoWorkflowsWorkflowID!) {
              duoWorkflowWorkflows(workflowId: $id) {
                nodes {
                  id
                  statusName
                  humanStatus
                  latestCheckpoint { duoMessages { content role status messageType } }
                }
              }
            }
          GQL

          data&.dig('duoWorkflowWorkflows', 'nodes')&.first
        end

        # Heartbeats on every status transition; otherwise every ~60s so CI
        # logs show signs of life.
        def log_progress(workflow_id, status, previous_status, started_at, principle: nil)
          elapsed = (Time.now.utc - started_at).to_i
          tag = workflow_tag(workflow_id, principle)

          if status != previous_status
            puts Rainbow("    workflow #{tag} status=#{status.downcase} (#{elapsed}s elapsed)").faint
            return
          end

          return unless elapsed.positive? && (elapsed % 60).between?(0, POLL_INTERVAL_SECONDS - 1)

          puts Rainbow("    workflow #{tag} still #{status.downcase}... (#{elapsed}s elapsed)").faint
        end

        # Formats a workflow identifier with optional principle name, e.g.
        # "3759465 (database-migrations)" or just "3759465".
        def workflow_tag(workflow_id, principle)
          principle ? "#{workflow_id} (#{principle})" : workflow_id.to_s
        end

        def current_git_branch
          branch = IO.popen(['git', '-C', Workspace.path, 'rev-parse', '--abbrev-ref', 'HEAD'],
            err: File::NULL, &:read).strip
          branch.empty? || branch == 'HEAD' ? default_branch : branch
        end

        def json_request(klass, url, headers: {}, body: {})
          uri = URI(url)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = uri.scheme == 'https'
          http.read_timeout = 120

          request = klass.new(uri)
          headers.each { |key, value| request[key] = value }
          request['Content-Type'] = 'application/json'
          request.body = body.to_json

          http.request(request)
        end
      end
    end
  end
end
