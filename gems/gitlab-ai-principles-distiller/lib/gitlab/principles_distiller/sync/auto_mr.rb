# frozen_string_literal: true

module Gitlab
  module PrinciplesDistiller
    class Sync
      module AutoMr
        # MR description has a 1 MB hard limit; multiple per-principle patches may be embedded, so each must stay well
        # under that.
        DIFF_MAX_LINES = 200
        DIFF_MAX_BYTES = 8_192

        PUSH_MAX_ATTEMPTS = 3
        PUSH_RETRY_BACKOFF_SECONDS = [5, 15].freeze

        # The run-invariant publish inputs: identical for every team branch and the tooling branch in a single
        # create_branch_and_mr call.
        PublishContext = Struct.new(
          :base_branch, :project_id, :api_token, :date, :auto_mr_cfg, :failed, :not_run,
          keyword_init: true
        )

        def distillation_base_sha
          @distillation_base_sha ||= resolve_distillation_base_sha
        end

        # Returns [text, truncated?]. Caps at DIFF_MAX_LINES or DIFF_MAX_BYTES, whichever hits first.
        def truncate_diff(text)
          lines = text.lines
          truncated = false

          if lines.size > DIFF_MAX_LINES
            lines = lines.first(DIFF_MAX_LINES)
            truncated = true
          end

          result = lines.join
          if result.bytesize > DIFF_MAX_BYTES
            # scrub: byteslice can split a multi-byte char; downstream JSON would blow up otherwise.
            result = result.byteslice(0, DIFF_MAX_BYTES).scrub
            result = result.sub(/[^\n]*\z/, '') # trim partial trailing line
            truncated = true
          end

          [result, truncated]
        end

        # Fans out the distilled changes into one MR per team group plus a separate "tooling" MR for the global
        # routing-table files. Each team's MR touches only that team's distilled files, so CODEOWNERS routes the
        # approval to the right reviewers (the global tooling files would otherwise pull every MR back to the broad
        # `/.ai/` owners).
        #
        # Teams are published independently: one team's failure is logged and the run continues with the rest, then a
        # non-zero exit is raised at the end so the scheduled job surfaces the partial failure.
        #
        # Each team branch, and the tooling branch, is either adopted from an already-open service-account MR or freshly
        # dated; see prefetch_adopted_branches! and branch_name_for.
        # This keeps at most one open MR per team across scheduled runs, instead of opening a new dated MR every week
        # the previous one goes unmerged.
        #
        # `failed` (principles that failed distillation, distinct from the per-team publish `failures` below) and
        # `not_run` (principles whose distill job never completed) travel with the rest of the run-invariant inputs via
        # `ctx` (see PublishContext).
        def create_branch_and_mr(distilled_contents, affected, auto_mr_cfg, failed: [], not_run: [])
          project_id = ENV.fetch(Env::CI_PROJECT_ID) do
            abort Rainbow("ERROR: #{Env::CI_PROJECT_ID} env var is required when --push is given").red
          end
          api_token = ENV.fetch(Env::GITLAB_API_TOKEN) do
            abort Rainbow("ERROR: #{Env::GITLAB_API_TOKEN} not set, cannot create MR").red
          end

          ctx = PublishContext.new(
            base_branch: workflow.default_branch,
            project_id: project_id,
            api_token: api_token,
            # UTC date for this run.
            # It names a brand-new branch, and it refreshes the title of every MR this run touches, so an adopted MR
            # shows its latest re-distillation date even though its branch keeps the original one.
            date: Time.now.utc.strftime('%Y%m%d'),
            auto_mr_cfg: auto_mr_cfg,
            failed: failed,
            not_run: not_run
          )

          teams = manifest.group_principles_by_team(distilled_contents.keys)
          prefetch_publish_inputs!(affected, teams, ctx)

          failures = []

          teams.each do |team, names|
            team_contents = distilled_contents.slice(*names)
            team_affected = affected.slice(*names)
            publish_team_branch(team, team_contents, team_affected, ctx)
          rescue StandardError => e
            warn Rainbow("ERROR: team '#{team}' failed: #{e.message}").red
            cleanup_branch(ctx.base_branch, team_branch_name(ctx.auto_mr_cfg, ctx.date, team))
            failures << team
          end

          begin
            publish_tooling_branch(ctx)
          rescue StandardError => e
            warn Rainbow("ERROR: tooling MR failed: #{e.message}").red
            cleanup_branch(ctx.base_branch, tooling_branch_name(ctx.auto_mr_cfg, ctx.date))
            failures << 'tooling'
          end

          return if failures.empty?

          abort Rainbow("\nERROR: #{failures.size} MR(s) failed: #{failures.join(', ')}").red
        end

        # Builds, pushes, and opens/updates a single team's MR. Raises on any
        # git/API failure so the caller can record the team and continue.
        def publish_team_branch(team, contents, affected, ctx)
          branch = team_branch_name(ctx.auto_mr_cfg, ctx.date, team)

          checkout_fresh_branch(branch, ctx.base_branch)

          # Writes deferred to here so the publish branch is the only diff.
          paths_to_commit = contents.map do |name, content|
            manifest.principles_path(name).tap do |path|
              File.write(Workspace.safe_join(path), content)
            end
          end

          system('git', '-C', Workspace.path, 'add', '-f', *paths_to_commit, exception: true)

          # A same-day re-run can reset the branch to identical content; in that case `git commit` would exit non-zero
          # ("nothing to commit") and the per-team rescue would record a spurious failure.
          # Skip the team MR instead (mirrors the guard in publish_tooling_branch).
          unless git_has_staged_changes?
            puts Rainbow("  #{team}: principles already up to date; skipping team MR.").faint
            close_adopted_mr_if_empty(branch, ctx)
            cleanup_branch(ctx.base_branch, branch)
            return
          end

          # The commit subject and body use the short team_slug, never the owner_team handle: handles can be long (and
          # would blow past the 72-char commit-line limit Danger enforces) and would @-mention the team from git
          # history.
          # The owner ping lives in the MR description (team_display) instead; CODEOWNERS still routes via the real
          # handle.
          # The principle list is a bullet per line so it never overflows 72
          # chars regardless of how many principles a team owns.
          slug = manifest.team_slug(team)
          updated_list = contents.keys.map { |name| "- #{name}" }.join("\n")

          commit_and_push(branch, ctx.project_id, ctx.api_token, <<~MSG.chomp)
        Update #{slug} AI development principles from SSOT

        Updated:
        #{updated_list}

        This commit was auto-generated by gitlab-ai-principles-distiller
        based on recent changes to development documentation.
          MSG

          title = "#{slug}: #{format(ctx.auto_mr_cfg['title_template'], date: ctx.date)}"
          create_mr(branch, contents, affected, ctx, team: team, title: title)
        end

        # Builds, pushes, and opens/updates the tooling MR carrying the global routing-table files (AGENTS.md,
        # CLAUDE.md, both SKILL.md, CODEOWNERS).
        # These are regenerated in-branch so they never leak into the per-team branches.
        #
        # The Duo review-instructions fences are NOT part of this MR: they are reconciled from merged-master content.
        # The separate scheduled reconcile job (see Sync#reconcile_duo_instructions_fences) keeps a team's distilled
        # MR and the fence update independently mergeable with no cross-MR merge-order dependency.
        def publish_tooling_branch(ctx)
          branch = tooling_branch_name(ctx.auto_mr_cfg, ctx.date)

          checkout_fresh_branch(branch, ctx.base_branch)

          # Regenerate the global artifacts now that we're on the tooling
          # branch, so the diff lands here rather than in any team branch.
          regenerate_static_artifacts

          existing = Manifest::TOOLING_PATHS.select { |p| stageable_tooling_path?(p) }

          # `git add -f` with no paths errors out (and `exception: true` would
          # raise), so skip the tooling MR when none of the routing-table files
          # exist on disk (e.g. AGENTS.md is absent, so nothing was generated).
          if existing.empty?
            puts Rainbow('  No tooling files found on disk; skipping tooling MR.').faint
            cleanup_branch(ctx.base_branch, branch)
            return
          end

          system('git', '-C', Workspace.path, 'add', '-f', *existing, exception: true)

          unless git_has_staged_changes?
            puts Rainbow('  Tooling files already up to date; skipping tooling MR.').faint
            close_adopted_mr_if_empty(branch, ctx)
            cleanup_branch(ctx.base_branch, branch)
            return
          end

          commit_and_push(branch, ctx.project_id, ctx.api_token, <<~MSG.chomp)
        Update AI principles routing tables (tooling)

        Regenerates AGENTS.md, CLAUDE.md, the gitlab-coding-principles
        SKILL.md files, and the per-file CODEOWNERS rules from the
        principles manifest.

        This commit was auto-generated by gitlab-ai-principles-distiller.
          MSG

          title = "tooling: #{format(ctx.auto_mr_cfg['title_template'], date: ctx.date)}"
          create_tooling_mr(branch, ctx, title)
        end

        # Builds, pushes, and opens/updates the dedicated reconcile MR carrying ONLY the Duo review-instructions fence
        # update.
        # Called from Sync#reconcile_duo_instructions_fences.
        #
        # The fences are projected AFTER cutting the fresh branch off origin/<default_branch>, so the projection reads
        # exactly the ref the MR targets.
        # This closes a race: if a team's distilled MR merges between the job starting and this branch being cut,
        # projecting first would derive the fences from the pre-merge working tree and the resulting MR could fail its
        # own (strict) guard against the newer base.
        # Regenerating on the freshly checked-out branch keeps the reconcile a pure projection of the branch's base. The
        # reconcile branch is date-free, so every re-run reuses the one open reconcile MR (see reconcile_branch_name and
        # submit_mr) rather than opening a new one each time.
        #
        # `regenerate` yields true when the projection changed the file on disk.
        # If nothing changed, master's fences already match its distilled files and no MR is needed.
        def create_reconcile_mr_from_working_tree(auto_mr_cfg, manifest)
          project_id = ENV.fetch(Env::CI_PROJECT_ID) do
            abort Rainbow("ERROR: #{Env::CI_PROJECT_ID} env var is required when --push is given").red
          end
          api_token = ENV.fetch(Env::GITLAB_API_TOKEN) do
            abort Rainbow("ERROR: #{Env::GITLAB_API_TOKEN} not set, cannot create MR").red
          end

          # No distillation happens on the reconcile path, so `failed` is always empty here (see PublishContext).
          ctx = PublishContext.new(
            base_branch: workflow.default_branch,
            project_id: project_id,
            api_token: api_token,
            date: Time.now.utc.strftime('%Y%m%d'),
            auto_mr_cfg: auto_mr_cfg,
            failed: [],
            not_run: []
          )

          branch = reconcile_branch_name(ctx.auto_mr_cfg)
          duo_path = Manifest::DUO_REVIEW_INSTRUCTIONS_PATH

          # Cut the branch first so the projection below reads the distilled files at the branch's base
          # (origin/<default_branch> HEAD), not the pipeline-SHA working tree.
          checkout_fresh_branch(branch, ctx.base_branch)

          changed = manifest.generate_duo_review_instructions
          unless changed
            puts Rainbow('  Duo review fences already up to date on master; skipping reconcile MR.').faint
            cleanup_branch(ctx.base_branch, branch)
            return
          end

          system('git', '-C', Workspace.path, 'add', '-f', duo_path, exception: true)

          unless git_has_staged_changes?
            puts Rainbow('  Duo review fences already up to date on master; skipping reconcile MR.').faint
            cleanup_branch(ctx.base_branch, branch)
            return
          end

          commit_and_push(branch, ctx.project_id, ctx.api_token, <<~MSG.chomp)
        Reconcile Duo review-instruction fences from master

        Regenerates the gem-managed fences in
        #{duo_path} from the committed distilled
        files by pure projection (no re-distillation).

        This commit was auto-generated by gitlab-ai-principles-distiller.
          MSG

          title = "reconcile fences: #{format(ctx.auto_mr_cfg['title_template'], date: ctx.date)}"
          create_reconcile_mr(branch, ctx, title)
        end

        def reconcile_branch_name(auto_mr_cfg)
          "#{auto_mr_cfg['branch_prefix']}-reconcile-fences"
        end

        def team_branch_name(auto_mr_cfg, date, team)
          branch_name_for(auto_mr_cfg, date, manifest.team_slug(team))
        end

        def tooling_branch_name(auto_mr_cfg, date)
          branch_name_for(auto_mr_cfg, date, 'tooling')
        end

        # Reuses the source branch of an already-open service-account MR for this slug.
        # If none was found during the run-level prefetch, mints a dated branch as before.
        # Keeping the original branch name is required because an existing MR cannot have its source_branch changed
        # through the API.
        # rubocop:disable Gitlab/ModuleWithInstanceVariables -- run-scoped branch cache on the host Sync instance
        def branch_name_for(auto_mr_cfg, date, slug)
          @adopted_branches&.fetch(slug, nil) || "#{auto_mr_cfg['branch_prefix']}-#{date}-#{slug}"
        end
        # rubocop:enable Gitlab/ModuleWithInstanceVariables

        # Branch off origin/<default_branch> (not the current HEAD) so the MR diff contains only our files.
        # The CI before_script fetches origin/<default_branch> for us.
        # `-B` resets the branch if a prior team iteration left it around.
        def checkout_fresh_branch(branch, base_branch)
          base_ref = "origin/#{base_branch}"
          system('git', '-C', Workspace.path, 'checkout', '--no-track', '-B', branch, base_ref, exception: true)
        end

        # Danger's commit-message linter (gitlab-dangerfiles) rejects any commit subject or body line longer than 72
        # chars (URLs exempt), which fails the danger-review job.
        # Auto-generated messages are built from team slugs and principle names, so guard here to fail fast at
        # generation time rather than discovering it only when the MR's pipeline runs.
        COMMIT_MAX_LINE_LENGTH = 72

        def assert_commit_lines_within_limit!(commit_msg)
          offenders = commit_msg.lines.map(&:chomp).reject do |line|
            line.length <= COMMIT_MAX_LINE_LENGTH || line.include?('://')
          end
          return if offenders.empty?

          detail = offenders.map { |l| "  (#{l.length}) #{l}" }.join("\n")
          raise "commit message has line(s) over #{COMMIT_MAX_LINE_LENGTH} chars:\n#{detail}"
        end

        def commit_and_push(branch, project_id, api_token, commit_msg)
          assert_commit_lines_within_limit!(commit_msg)
          system('git', '-C', Workspace.path, 'commit', '-m', commit_msg, exception: true)
          # The branch is auto-generated and always rebuilt from origin/<default_branch>.
          # An adopted branch can carry reviewer commits, so prefetch_adopted_branches! warns before this force-push
          # when its tip was not authored by the configured service account.
          # (--force-with-lease would require fetching every adopted branch.)
          push_url = push_remote_url(project_id)
          env = git_push_env(api_token, push_url)
          push_with_retries(env, push_url, branch)
        end

        def git_has_staged_changes?
          !system('git', '-C', Workspace.path, 'diff', '--cached', '--quiet')
        end

        # A tooling path is stageable only if it exists AND no directory *within the workspace* on the way to it is a
        # symlink.
        # `git add` refuses paths "beyond a symbolic link", which happens here because some repos symlink
        # `.agents/skills` -> `.claude/skills`: the file is real but its canonical location is staged via the
        # `.claude/...` entry, so skipping the symlinked alias avoids the `exit 128` without losing content.
        #
        # The comparison is anchored at the resolved workspace root so a symlink *in the workspace path itself* (e.g.
        # macOS `/tmp` -> `/private/tmp`, or a CI runner mounting the workspace through a symlink) does not cause every
        # tooling path to be filtered out.
        def stageable_tooling_path?(relative_path)
          full = Workspace.safe_join(relative_path)
          return false unless File.exist?(full)

          dir = File.dirname(full)
          relative_dir = File.dirname(relative_path)
          workspace_path = File.realpath(Workspace.path)
          expected = relative_dir == '.' ? workspace_path : File.join(workspace_path, relative_dir)

          File.realpath(dir) == expected
        rescue Errno::ENOENT
          false
        end

        # Returns to the base branch, warning (rather than failing silently) if the checkout does not succeed so a stuck
        # working tree is visible.
        def checkout_base_or_warn(base_branch)
          return if system('git', '-C', Workspace.path, 'checkout', base_branch)

          warn Rainbow("  WARNING: checkout to #{base_branch} failed; " \
            'the working tree may still be on the publish branch').yellow
        end

        def cleanup_branch(base_branch, branch)
          base_branch ||= workflow.default_branch

          checkout_base_or_warn(base_branch)

          return if system('git', '-C', Workspace.path, 'branch', '-D', branch)

          warn Rainbow("  WARNING: cleanup deletion of branch #{branch} failed; " \
            'remove it manually if unwanted').yellow
        end

        # Renders the per-principle section embedded in the auto-MR description: principle heading, source-file
        # commit-history links, and a fenced `git diff prior_sha..origin/<default_branch>`.
        def principle_diff_section(name, affected_entry, default_branch)
          sources = affected_entry&.dig(:changed_sources) || []
          prior_sha = affected_entry&.dig(:prior_sha)
          baseline_path = affected_entry&.dig(:config)&.dig('baseline')
          project_url = "#{workflow.gitlab_host}/#{workflow.catalog_project_path}"

          lines = ["#### `#{name}`"]

          if sources.any?
            lines << ''
            lines << "<details><summary>Source files (#{sources.size})</summary>"
            lines << ''
            sources.each do |source|
              path = source['path']
              commits_url = "#{project_url}/-/commits/#{default_branch}/#{path}"
              lines << "- [`#{path}`](#{commits_url})"
            end
            lines << ''
            lines << '</details>'
          end

          paths = sources.map { |s| s['path'] } # -- standalone script without Rails
          paths.unshift(baseline_path) if baseline_path
          diff_text, truncated = compute_principle_diff(prior_sha, default_branch, paths)

          if diff_text
            # 4-backtick fence: ```diff/```ruby blocks inside SSOT files would otherwise close the outer fence early.
            # Resolved SHA (not branch name): range stays meaningful as master moves on.
            target_sha = distillation_base_sha
            lines << ''
            lines << "<details><summary>SSOT diff since previous distillation " \
              "(#{prior_sha[0, 12]} \u2192 #{target_sha[0, 12]})</summary>"
            lines << ''
            lines << '````diff'
            lines << diff_text.chomp

            if truncated
              lines << ''
              lines << "... (diff truncated at #{DIFF_MAX_LINES} lines / #{DIFF_MAX_BYTES / 1024} KB; " \
                'use the per-file commit-history links above for the full picture)'
            end

            lines << '````'
            lines << ''
            lines << '</details>'
          end

          lines.join("\n")
        end

        private

        # Force-pushes the branch, retrying on transient failures (e.g. HTTP 502, "the remote end hung up unexpectedly")
        # with short exponential backoff.
        # The push targets our own auto-generated branch, always rebuilt from origin/<default_branch>, so a force-push
        # is idempotent and retrying is safe.
        # `system(..., exception: true)` raises on a non-zero git exit or a spawn failure; we re-raise the last error
        # once attempts are exhausted so the caller's per-team rescue records it.
        def push_with_retries(env, push_url, branch)
          attempt = 0
          begin
            attempt += 1
            system(env, 'git', '-C', Workspace.path, 'push', '--force', push_url,
              "#{branch}:#{branch}", exception: true)
          rescue StandardError => e
            raise if attempt >= PUSH_MAX_ATTEMPTS

            # fetch-with-fallback so bumping PUSH_MAX_ATTEMPTS without adding a
            # matching backoff entry degrades to the last value rather than
            # sleep(nil).
            backoff = PUSH_RETRY_BACKOFF_SECONDS.fetch(attempt - 1, PUSH_RETRY_BACKOFF_SECONDS.last)
            warn Rainbow("    WARNING: push of #{branch} failed " \
              "(attempt #{attempt}/#{PUSH_MAX_ATTEMPTS}): #{e.message}; " \
              "retrying in #{backoff}s...").yellow
            sleep(backoff)
            retry
          end
        end

        # CI runners only have origin/<branch>, not a local <branch> ref.
        # Try remote-tracking first, then local, then HEAD as a fallback.
        def resolve_distillation_base_sha
          branch = workflow.default_branch
          ["origin/#{branch}", branch].each do |ref|
            out = IO.popen(['git', '-C', Workspace.path, 'merge-base', 'HEAD', ref], err: File::NULL, &:read).strip
            return out unless out.empty?
          end
          IO.popen(['git', '-C', Workspace.path, 'rev-parse', 'HEAD'], err: File::NULL, &:read).strip
        end

        # CI's shallow clone doesn't include prior SHAs from weeks ago.
        # Fetch each unique prior_sha so `git diff <prior_sha>..origin/master` resolves later.
        # Relies on GitLab.com's `uploadpack.allowReachableSHA1InWant=true` for direct-SHA fetches.
        def prefetch_prior_shas!(affected)
          shas = affected.values.filter_map { |entry| entry[:prior_sha] }.uniq
          return if shas.empty?

          shas.each do |sha|
            next if sha_present_locally?(sha)

            puts Rainbow("    prefetching #{sha[0, 12]} for diff embedding...").faint
            success = system('git', '-C', Workspace.path, 'fetch', '--depth=1', 'origin', sha,
              out: File::NULL, err: File::NULL)

            unless success
              warn Rainbow("    WARNING: could not fetch #{sha[0, 12]}; diff embedding will fall back").yellow
            end
          end
        end

        def prefetch_publish_inputs!(affected, teams, ctx)
          # Fetch every prior SHA once up front so each team branch can embed its SSOT diffs without re-fetching.
          prefetch_prior_shas!(affected)

          # Resolve adoption for every branch this run will touch, once, before any branch is cut.
          # `team_slug` is the same key `team_branch_name` derives its suffix from, plus the fixed `tooling` slug.
          slugs = teams.keys.map { |team| manifest.team_slug(team) } + ['tooling']
          prefetch_adopted_branches!(ctx, slugs)
        end

        # Finds open auto-MRs owned by the service account and records their branches by team or tooling slug.
        # This lookup happens once per collect run, before any force-push, so a weekly run refreshes an existing MR
        # rather than opening another dated one.
        # Best-effort: an API or identity lookup failure preserves the old fresh-branch behaviour.
        # rubocop:disable Gitlab/ModuleWithInstanceVariables -- run-scoped branch cache on the host Sync instance
        def prefetch_adopted_branches!(ctx, slugs)
          @adopted_branches = {}
          @adopted_mrs = {}
          author_id = mr_assignee_id(ctx.api_token)
          return unless author_id

          encoded_project = URI.encode_www_form_component(ctx.project_id)
          open_mrs = open_mrs_by_author(encoded_project, author_id, ctx.api_token)
          return unless open_mrs

          prefix = Regexp.escape(ctx.auto_mr_cfg.fetch('branch_prefix'))
          slugs.each do |slug|
            pattern = /\A#{prefix}-\d{8}-#{Regexp.escape(slug)}\z/
            mr = open_mrs.find do |candidate|
              pattern.match?(candidate['source_branch'].to_s) &&
                candidate['source_project_id'] == candidate['target_project_id'] &&
                candidate['target_branch'] == ctx.base_branch
            end
            next unless mr

            @adopted_branches[slug] = mr.fetch('source_branch')
            @adopted_mrs[mr.fetch('source_branch')] = mr
            warn_if_adopted_branch_has_foreign_tip(encoded_project, mr, ctx.api_token)
          end
        rescue StandardError => e
          @adopted_branches = {}
          @adopted_mrs = {}
          warn Rainbow("WARNING: could not look up open distillation MRs (#{e.message}); using fresh branches").yellow
        end
        # rubocop:enable Gitlab/ModuleWithInstanceVariables

        def open_mrs_by_author(encoded_project, author_id, api_token)
          uri = URI("#{workflow.gitlab_host}/api/v4/projects/#{encoded_project}/merge_requests")
          uri.query = URI.encode_www_form(
            state: 'opened', author_id: author_id, order_by: 'created_at', sort: 'desc', per_page: 100
          )
          response = authenticated_get(uri, api_token)
          unless response.is_a?(Net::HTTPSuccess)
            warn Rainbow("WARNING: open distillation MR lookup failed (#{response.code}); using fresh branches").yellow
            return
          end

          JSON.parse(response.body)
        end

        def warn_if_adopted_branch_has_foreign_tip(encoded_project, mr, api_token)
          expected_email = configured_git_user_email
          sha = mr['sha'].to_s
          return if expected_email.empty? || sha.empty?

          encoded_sha = URI.encode_www_form_component(sha)
          uri = URI("#{workflow.gitlab_host}/api/v4/projects/#{encoded_project}/repository/commits/#{encoded_sha}")
          response = authenticated_get(uri, api_token)
          unless response.is_a?(Net::HTTPSuccess)
            warn Rainbow("WARNING: could not verify adopted branch #{mr['source_branch']} tip " \
              "(HTTP #{response.code}); the generated force-push will proceed").yellow
            return
          end

          commit = JSON.parse(response.body)
          author_email = commit['author_email'].to_s
          return if author_email.empty? || author_email.casecmp?(expected_email)

          warn Rainbow("WARNING: adopted branch #{mr['source_branch']} tip #{sha[0, 12]} was authored by " \
            "#{commit['author_name']} <#{author_email}>; the generated force-push will discard that commit").yellow
        rescue StandardError => e
          warn Rainbow("WARNING: could not verify adopted branch #{mr['source_branch']} tip (#{e.message})").yellow
        end

        def configured_git_user_email
          IO.popen(['git', '-C', Workspace.path, 'config', '--get', 'user.email'], err: File::NULL, &:read).strip
        end

        def authenticated_get(uri, api_token)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = uri.scheme == 'https'
          http.read_timeout = 60
          request = Net::HTTP::Get.new(uri)
          request['PRIVATE-TOKEN'] = api_token
          http.request(request)
        end

        # A reused branch can end up empty when a later distillation decides master already has the correct content.
        # Close that now-obsolete MR instead of leaving its previous generated commit open indefinitely.
        # rubocop:disable Gitlab/ModuleWithInstanceVariables -- run-scoped MR cache on the host Sync instance
        def close_adopted_mr_if_empty(branch, ctx)
          mr = @adopted_mrs&.fetch(branch, nil)
          return unless mr

          encoded_project = URI.encode_www_form_component(ctx.project_id)
          response = workflow.put_json(
            "#{workflow.gitlab_host}/api/v4/projects/#{encoded_project}/merge_requests/#{mr.fetch('iid')}",
            headers: { 'PRIVATE-TOKEN' => ctx.api_token },
            body: { state_event: 'close' }
          )
          return if response.is_a?(Net::HTTPSuccess)

          warn Rainbow("WARNING: could not close empty adopted MR !#{mr['iid']} (#{response.code})").yellow
        rescue StandardError => e
          warn Rainbow("WARNING: could not close empty adopted MR for #{branch} (#{e.message})").yellow
        end
        # rubocop:enable Gitlab/ModuleWithInstanceVariables

        def sha_present_locally?(sha)
          system('git', '-C', Workspace.path, 'cat-file', '-e', "#{sha}^{commit}", out: File::NULL, err: File::NULL)
        end

        # Returns [diff_text, truncated?]. diff_text is nil when prior_sha is unreachable or the diff is empty.
        def compute_principle_diff(prior_sha, default_branch, paths)
          return [nil, false] if prior_sha.nil? || prior_sha.empty? || paths.empty?
          return [nil, false] unless sha_present_locally?(prior_sha)

          target_ref = "origin/#{default_branch}"
          cmd = ['git', '-C', Workspace.path, 'diff', "#{prior_sha}..#{target_ref}", '--', *paths]
          out = IO.popen(cmd, err: File::NULL, &:read)
          return [nil, false] if out.nil? || out.strip.empty?

          truncate_diff(out)
        end

        # Returns an open MR for the given source branch, or nil.
        # `order_by=created_at&sort=desc` is explicit because the API default is implementation-defined.
        def find_open_mr(encoded_project, source_branch, api_token)
          uri = URI("#{workflow.gitlab_host}/api/v4/projects/#{encoded_project}/merge_requests")
          uri.query = URI.encode_www_form(state: 'opened', source_branch: source_branch,
            order_by: 'created_at', sort: 'desc')
          response = authenticated_get(uri, api_token)
          return nil unless response.is_a?(Net::HTTPSuccess)

          mrs = JSON.parse(response.body)
          mrs.first
        end

        # The MR author's user ID (the service account whose token we use), memoized for the run.
        # Used as the assignee so Danger's "no assignee" warning doesn't fire. Returns nil on any failure (best-effort).
        #
        # Memoize with `defined?` (not `||=`) so a nil result (any failure path) is cached too; otherwise every team in
        # a fan-out run would re-issue the failed lookup.
        # The ivar lives on the Sync instance this module is mixed into, matching the existing run-scoped memos here.
        # rubocop:disable Gitlab/ModuleWithInstanceVariables -- run-scoped memo on the host Sync instance
        def mr_assignee_id(api_token)
          return @mr_assignee_id if defined?(@mr_assignee_id)

          @mr_assignee_id = fetch_current_user_id(api_token)
        end
        # rubocop:enable Gitlab/ModuleWithInstanceVariables

        def reviewer_resolver
          @reviewer_resolver ||= ReviewerResolver.new(
            workflow: workflow,
            distillation_base_sha: distillation_base_sha
          )
        end

        def fetch_current_user_id(api_token)
          uri = URI("#{workflow.gitlab_host}/api/v4/user")
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = uri.scheme == 'https'
          http.read_timeout = 60
          request = Net::HTTP::Get.new(uri)
          request['PRIVATE-TOKEN'] = api_token
          response = http.request(request)
          unless response.is_a?(Net::HTTPSuccess)
            warn Rainbow("WARNING: could not resolve current user for assignee (#{response.code}); " \
              'leaving MR unassigned').yellow
            return nil
          end

          JSON.parse(response.body)['id']
        rescue StandardError => e
          warn Rainbow("WARNING: could not resolve current user for assignee (#{e.message}); " \
            'leaving MR unassigned').yellow
          nil
        end

        # The numeric ID of the milestone matching the repo's in-development version (read from the root `VERSION` file,
        # e.g. `19.1.0-pre` -> `19.1`), looked up among the project's milestones (including ancestor-group milestones).
        # Memoized for the run.
        # Returns nil when VERSION is unreadable or no milestone matches (best-effort: the MR is created without a
        # milestone).
        # rubocop:disable Gitlab/ModuleWithInstanceVariables -- run-scoped memo on the host Sync instance
        def current_milestone_id(encoded_project, api_token)
          return @current_milestone_id if defined?(@current_milestone_id)

          title = version_milestone_title
          @current_milestone_id = title && lookup_milestone_id(encoded_project, api_token, title)
        end
        # rubocop:enable Gitlab/ModuleWithInstanceVariables

        # Reads the root VERSION file and returns its MAJOR.MINOR (e.g. `19.1.0-pre` -> `19.1`), or nil if it cannot be
        # read or parsed.
        def version_milestone_title
          raw = File.read(Workspace.safe_join('VERSION')).strip
          major_minor = raw.split('.').first(2).join('.')
          /\A\d+\.\d+\z/.match?(major_minor) ? major_minor : nil
        rescue StandardError => e
          warn Rainbow("WARNING: could not read VERSION for milestone (#{e.message}); " \
            'leaving MR without a milestone').yellow
          nil
        end

        # Resolves a milestone title to its ID. Checks project milestones first (includes ancestor-group milestones via
        # include_ancestors), so it works whether the milestone is defined on the project or its group.
        # Returns nil when no active milestone matches the title.
        def lookup_milestone_id(encoded_project, api_token, title)
          uri = URI("#{workflow.gitlab_host}/api/v4/projects/#{encoded_project}/milestones")
          uri.query = URI.encode_www_form(title: title, include_ancestors: true)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = uri.scheme == 'https'
          http.read_timeout = 60
          request = Net::HTTP::Get.new(uri)
          request['PRIVATE-TOKEN'] = api_token
          response = http.request(request)
          unless response.is_a?(Net::HTTPSuccess)
            warn Rainbow("WARNING: milestone lookup for #{title} failed (#{response.code}); " \
              'leaving MR without a milestone').yellow
            return nil
          end

          milestone = JSON.parse(response.body).find { |m| m['title'] == title }
          unless milestone
            warn Rainbow("WARNING: no milestone titled #{title}; leaving MR without a milestone").yellow
            return nil
          end

          milestone['id']
        rescue StandardError => e
          # A 2xx-but-non-JSON body (e.g. an HTML proxy/error page) would raise JSON::ParserError here; keep milestone
          # lookup best-effort so it never fails the whole team's MR.
          warn Rainbow("WARNING: milestone lookup for #{title} failed (#{e.message}); " \
            'leaving MR without a milestone').yellow
          nil
        end

        # Returns the plain HTTPS push URL with no embedded credentials. Authentication is supplied separately via
        # `git_push_env`, which injects an `Authorization: Bearer` header through `GIT_CONFIG_*` env vars so the token
        # never lands in argv, the URL, or git's reflog.
        def push_remote_url(project_path_or_id)
          host = URI(workflow.gitlab_host).host || 'gitlab.com'
          # CI_PROJECT_ID is numeric, not usable as a URL path.
          project_path = ENV.fetch(Env::CI_PROJECT_PATH, nil)
          if project_path.nil? || project_path.empty?
            if project_path_or_id.to_s.match?(/\A\d+\z/)
              abort Rainbow("ERROR: #{Env::CI_PROJECT_PATH} env var is required for git push " \
                "(numeric #{Env::CI_PROJECT_ID} alone is not enough)").red
            end

            project_path = project_path_or_id.to_s
          end

          "https://#{host}/#{project_path}.git"
        end

        # Injects the API token as an HTTP Basic `Authorization` header via
        # `GIT_CONFIG_COUNT`/`GIT_CONFIG_KEY_*`/`GIT_CONFIG_VALUE_*` env vars
        # (https://git-scm.com/docs/git-config#Documentation/git-config.txt-GITCONFIGCOUNT).
        # This keeps the token out of:
        # - argv (no `git -c http.extraHeader=...` and no credentialed URL).
        # - the remote URL and git's reflog.
        # Returns the env hash to pass to the push `system` call.
        #
        # The header is scoped to the host (`http.https://<host>.extraHeader`), not the full repo URL. git matches
        # `http.<url>.*` by URL prefix on whole path segments, so a key scoped to `.../gitlab` does NOT match a request
        # to `.../gitlab.git`.
        # That mismatch left the header unapplied and the push fell back to anonymous, yielding a 403.
        # A host-scoped key applies to every request to that host, which is what we want for a single-remote push.
        #
        # The scheme must be HTTP Basic (`oauth2:<token>`, base64-encoded), not `Bearer`: GitLab's smart-HTTP git
        # endpoint authenticates PATs via Basic auth.
        # A `Bearer` header is silently ignored, so the request falls through to git's Basic challenge with no
        # credentials and the remote returns `HTTP Basic: Access denied`. (`PRIVATE-TOKEN` is REST-only and also
        # rejected on git push.)
        #
        # Appends to any existing `GIT_CONFIG_*` entries injected by the parent environment (e.g. GitLab Runner) rather
        # than overwriting them.
        def git_push_env(api_token, push_url)
          abort Rainbow("ERROR: #{Env::GITLAB_API_TOKEN} is empty, cannot push").red if api_token.to_s.empty?

          host_scope = URI(push_url).then { |u| "#{u.scheme}://#{u.host}" }
          # `pack('m0')`: strict base64 with no trailing newline.
          basic_credentials = ["oauth2:#{api_token}"].pack('m0')
          next_index = ENV.fetch('GIT_CONFIG_COUNT', '0').to_i

          {
            'GIT_CONFIG_COUNT' => (next_index + 1).to_s,
            "GIT_CONFIG_KEY_#{next_index}" => "http.#{host_scope}.extraHeader",
            "GIT_CONFIG_VALUE_#{next_index}" => "Authorization: Basic #{basic_credentials}"
          }
        end

        def create_mr(branch, changed_principles, affected, ctx, team:, title:)
          default_branch = workflow.default_branch
          sections = changed_principles.keys.map do |name|
            principle_diff_section(name, affected[name], default_branch)
          end.join("\n\n")

          project_url = "#{workflow.gitlab_host}/#{workflow.catalog_project_path}"
          manifest_url = "#{project_url}/-/blob/#{default_branch}/.ai/principles/manifest.yml"
          ci_yml_url = "#{project_url}/-/blob/#{default_branch}/.gitlab/ci/sync-principles.gitlab-ci.yml"

          # Ping the individuals who actually changed the SSOT docs rather than the whole owning team.
          # Falls back to the team ping (or the non-mention slug when fallback_ping_team: false) only when no author
          # resolves (see team_display).
          author_entries = affected.slice(*changed_principles.keys)
          authors = reviewer_resolver.ssot_authors(author_entries)
          mentions = authors.map { |author| "@#{author[:username]}" }
          reviewer_ids = authors.filter_map { |author| author[:id] }
          fallback_reviewer = reviewer_resolver.owner_team_reviewer(team) if reviewer_ids.empty?
          outcome = ping_outcome(mentions, fallback_reviewer)
          ping_line = ping_line_for(outcome, mentions, fallback_reviewer, team)

          description = <<~DESC
        ## Summary

        This MR updates AI development principles based on recent changes to the
        development documentation (SSOT). #{ping_line} It is one of several
        team-scoped MRs from this run; the global routing tables (AGENTS.md,
        CLAUDE.md, SKILL.md) are updated in a separate tooling MR.
        #{why_you_were_pinged_section(outcome)}
        #{review_request_section(changed_principles.keys, team)}
        #{failed_principles_section(ctx.failed)}
        #{not_run_principles_section(ctx.not_run)}
        ### Updated principles and their source-doc changes

        #{sections}

        ### How this works

        A [scheduled CI job](#{ci_yml_url}) detects changes to `doc/development/`
        files listed in [`.ai/principles/manifest.yml`](#{manifest_url}), then
        uses the GitLab Duo Agent Platform Workflow API to distill updated
        principles for the affected domains.
        #{job_line}
        Please review the checklist changes to ensure they accurately
        reflect the documentation updates.
          DESC

          reviewer_ids = [fallback_reviewer[:id]] if reviewer_ids.empty? && fallback_reviewer
          submit_mr(branch, default_branch, ctx, title, description, reviewer_ids: reviewer_ids)
        end

        # Opens/updates the tooling MR carrying the regenerated global routing tables. Routed to the broad `/.ai/`
        # owners (no SSOT-team content).
        def create_tooling_mr(branch, ctx, title)
          default_branch = workflow.default_branch
          project_url = "#{workflow.gitlab_host}/#{workflow.catalog_project_path}"
          manifest_url = "#{project_url}/-/blob/#{default_branch}/.ai/principles/manifest.yml"

          description = <<~DESC
        ## Summary

        This MR regenerates the global AI-principles routing tables from
        [`.ai/principles/manifest.yml`](#{manifest_url}): `AGENTS.md`,
        `CLAUDE.md`, the `gitlab-coding-principles` SKILL.md files, and the
        per-file CODEOWNERS rules.

        These files embed the routing table for **all** principles, so they are
        kept separate from the per-team principle MRs in this run.
        #{job_line}
        No distilled principle content changes here — only the generated
        routing tables. The Duo review-instruction fences are reconciled
        separately by the scheduled fence-reconcile job.
          DESC

          submit_mr(branch, default_branch, ctx, title, description)
        end

        # Opens/updates the dedicated reconcile MR carrying only the Duo review-instruction fence update, projected from
        # merged master.
        # Routed to the broad `/.gitlab/` owners (the Duo file is not assigned per-principle in CODEOWNERS).
        def create_reconcile_mr(branch, ctx, title)
          default_branch = workflow.default_branch
          duo_path = Manifest::DUO_REVIEW_INSTRUCTIONS_PATH

          description = <<~DESC
        ## Summary

        This MR reconciles the gem-managed fences in `#{duo_path}` with the
        committed distilled principles on `#{default_branch}`.

        The fences are regenerated by **pure projection** of the merged-master
        distilled files (their `distilled_at_sha` / `source_checksum` are copied
        from each distilled file's frontmatter) — **no re-distillation runs
        here**, so this MR is idempotent and passes the
        `ai-duo-review-instructions` guard on its own.
        #{job_line}
        No distilled principle content changes here — only the generated Duo
        review fences.
          DESC

          submit_mr(branch, default_branch, ctx, title, description)
        end

        def job_line
          job_url = ENV.fetch(Env::CI_JOB_URL, nil)
          return '' if job_url.nil? || job_url.empty?

          "\nThis MR was generated by #{job_url}\n"
        end

        # `failed` is run-wide (distillation failures aren't grouped by team), so the same note is repeated in every
        # team's MR description.
        def failed_principles_section(failed)
          return '' if failed.empty?

          <<~SECTION

            > ⚠️ **Partial run**: #{failed.size} principle(s) failed distillation after retries and are
            > NOT included here: #{failed.join(', ')}. They will be re-attempted on the next scheduled run.
          SECTION
        end

        # Worded deliberately differently from failed_principles_section: these principles were never shown to be
        # undistillable, their distill job simply did not complete (runner outage, job timeout, or the pipeline
        # being canceled).
        # Conflating the two would send an operator looking for a distillation defect that does not exist.
        #
        # Like `failed`, this is run-wide rather than per-team, so the same note appears in every team's MR description.
        def not_run_principles_section(not_run)
          return '' if not_run.to_a.empty?

          <<~SECTION

            > ℹ️ **Incomplete run**: #{not_run.size} principle(s) produced no result because their
            > distill job did not complete: #{not_run.join(', ')}. This is not a distillation
            > failure: they will be re-attempted on the next scheduled run.
          SECTION
        end

        # Which of the four ping paths `ping_line_for` took. Named so the "why you were pinged" prose can describe
        # what actually happened rather than asserting one path for every MR.
        def ping_outcome(mentions, fallback_reviewer)
          if mentions.any?
            fallback_reviewer ? :authors_with_fallback : :authors
          else
            fallback_reviewer ? :fallback : :team_only
          end
        end

        # Names *who* is being asked to review. Four outcomes, because an author may resolve without being assignable
        # (no user ID), and the owning team may yield no assignable member at all (see owner_team_reviewer, which
        # returns nil for an unresolvable group).
        def ping_line_for(outcome, mentions, fallback_reviewer, team)
          case outcome
          when :authors_with_fallback
            "Recent SSOT changes here were authored by #{mentions.join(' ')} — please review. " \
              "Reviewer assignment routed to @#{fallback_reviewer[:username]} from " \
              "**#{manifest.team_display(team)}**."
          when :fallback
            "No SSOT author resolved; routing to @#{fallback_reviewer[:username]} from " \
              "**#{manifest.team_display(team)}**."
          when :team_only
            "Please review: **#{manifest.team_display(team)}**."
          else
            "Recent SSOT changes here were authored by #{mentions.join(' ')} — please review."
          end
        end

        # Explains why the recipient was pinged and why merging (not just reviewing) matters.
        #
        # The ping line above names *who* is being asked; this says *why they specifically* got it, because the paths
        # look identical from the recipient's side. Someone reached through a fallback has no obvious connection to the
        # change and can reasonably assume the ping was a mistake.
        #
        # The opening sentence is per-outcome: asserting "you changed the SSOT documentation" is false on the fallback
        # paths, and on :team_only nobody was individually pinged at all. The merging paragraph is unconditional: it
        # matters most on :team_only, where the MR looks unowned and is likeliest to stall.
        #
        # Collapsed so it does not push the diffs further down for readers who already know the process.
        def why_you_were_pinged_section(outcome)
          <<~SECTION

            <details><summary>Why you were pinged, and why this needs merging</summary>

            #{why_you_were_pinged_reason(outcome)}

            These MRs need to be **reviewed and merged**, not just reviewed: the
            distilled principles only reach the `gitlab-coding-principles` that
            AI agents load once this is merged. An unmerged MR is re-distilled
            and reopened on the next weekly run, so the improvement stays
            unavailable to agents until someone merges it.

            </details>
          SECTION
        end

        # :team_only covers both team_display forms: the raw handle (which group-pings) and the non-mention slug used
        # when fallback_ping_team is false, so the wording must not claim anyone was mentioned.
        def why_you_were_pinged_reason(outcome)
          case outcome
          when :authors_with_fallback
            'You were pinged because you changed the SSOT documentation these ' \
              'principles are distilled from. Because none of you could be ' \
              'assigned automatically, a member of the owning team was assigned ' \
              'as reviewer.'
          when :fallback
            'No documentation author could be resolved for these changes, so ' \
              'review was routed to the least-loaded available member of the ' \
              'owning team.'
          when :team_only
            'No individual could be resolved for these changes, so this merge ' \
              'request is routed to the owning team, which approves through ' \
              'CODEOWNERS.'
          else
            'You were pinged because you changed the SSOT documentation these ' \
              'principles are distilled from.'
          end
        end

        # Renders the "Request a review from" section listing secondary teams for the principles in this MR whose SSOT
        # docs span more than one owner.
        # Returns '' when there are no secondary teams, so single-owner MRs stay terse (the owner already approves via
        # CODEOWNERS).
        #
        # Secondary handles are rendered as inline code (`@team`) rather than bare mentions, so listing them does not
        # notify the whole secondary group; only the primary team is pinged (via CODEOWNERS and the summary).
        # Secondary teams are deduped and exclude the primary.
        def review_request_section(principle_names, team)
          secondary = principle_names
            .flat_map { |name| manifest.principle_secondary_teams(name) }
            .reject { |handle| handle.to_s.strip.empty? || handle == team }
            .uniq
          return '' if secondary.empty?

          <<~SECTION

            ### Request a review from

            Approval is routed to the primary owner via CODEOWNERS. Some SSOT
            docs in this MR also affect other teams — consider requesting a
            review from:

            #{secondary.map { |handle| "- `#{handle}`" }.join("\n")}
          SECTION
        end

        # Shared create-or-update.
        # Branch adoption lets this find an open MR across scheduled runs, while a same-day fresh branch stays
        # idempotent.
        # Either way the MR is updated in place rather than failing on a 409.
        def submit_mr(branch, default_branch, ctx, title, description, reviewer_ids: [])
          encoded_project = URI.encode_www_form_component(ctx.project_id)
          existing_mr = find_open_mr(encoded_project, branch, ctx.api_token)
          body = mr_body(ctx, title, description)
          # Assign the MR to its author (the service account) and tag the current milestone so Danger's "no assignee" /
          # "no milestone" warnings don't fire on every weekly auto-MR. Both are best-effort: a lookup failure logs and
          # omits the field rather than aborting.
          assignee_id = mr_assignee_id(ctx.api_token)
          body[:assignee_id] = assignee_id if assignee_id
          milestone_id = current_milestone_id(encoded_project, ctx.api_token)
          body[:milestone_id] = milestone_id if milestone_id
          existing_reviewer_ids = existing_mr.to_h.fetch('reviewers', []).filter_map { |reviewer| reviewer['id']&.to_i }
          merged_reviewer_ids = (existing_reviewer_ids + reviewer_ids).uniq
          body[:reviewer_ids] = merged_reviewer_ids if merged_reviewer_ids.any?

          response, action = submit_mr_request(existing_mr, encoded_project, branch, default_branch, ctx, body)

          if body[:reviewer_ids] && !response.is_a?(Net::HTTPSuccess)
            warn Rainbow("WARNING: reviewer assignment failed (#{response.code}); retrying without reviewers").yellow
            body.delete(:reviewer_ids)
            response, = submit_mr_request(existing_mr, encoded_project, branch, default_branch, ctx, body)
          end

          unless response.is_a?(Net::HTTPSuccess)
            # Raise (not abort) so the per-team rescue in create_branch_and_mr can record this team and continue with
            # the others.
            raise "Failed to #{action.delete_suffix('ed')} MR: #{response.code} #{response.body.slice(0, 200)}"
          end

          response_body = JSON.parse(response.body)
          warn_if_reviewers_dropped(body[:reviewer_ids], response_body['reviewers'])
          puts "\n#{Rainbow("MR #{action}: #{response_body['web_url']}").green}"
        end

        def mr_body(ctx, title, description)
          {
            title: title,
            # Collapse runs of blank lines so an empty `job_line` (when CI_JOB_URL is unset) doesn't leave a spurious
            # gap mid-paragraph.
            description: description.gsub(/\n{3,}/, "\n\n"),
            labels: Array(ctx.auto_mr_cfg['labels']).join(','),
            remove_source_branch: ctx.auto_mr_cfg.fetch('remove_source_branch', true)
          }
        end

        def submit_mr_request(existing_mr, encoded_project, branch, default_branch, ctx, body)
          if existing_mr
            response = workflow.put_json(
              "#{workflow.gitlab_host}/api/v4/projects/#{encoded_project}/merge_requests/#{existing_mr.fetch('iid')}",
              headers: { 'PRIVATE-TOKEN' => ctx.api_token }, body: body
            )
            [response, 'updated']
          else
            response = workflow.post_json(
              "#{workflow.gitlab_host}/api/v4/projects/#{encoded_project}/merge_requests",
              headers: { 'PRIVATE-TOKEN' => ctx.api_token },
              body: body.merge(source_branch: branch, target_branch: default_branch)
            )
            [response, 'created']
          end
        end

        def warn_if_reviewers_dropped(requested_ids, reviewers)
          return unless requested_ids

          returned_ids = Array(reviewers).filter_map { |reviewer| reviewer['id']&.to_i }
          dropped_ids = requested_ids - returned_ids
          return if dropped_ids.empty?

          warn Rainbow("WARNING: GitLab did not assign reviewer IDs: #{dropped_ids.join(', ')}").yellow
        end
      end
    end
  end
end
