# frozen_string_literal: true

# Mirrors `.ai/principles/distillation_prompt.md` and a read-only tool
# allowlist into the AI Catalog "Agent Principles Distiller" Flow used
# by sync.rb via the Duo Workflow API. Idempotent: creates the flow if
# missing, releases a new version only on drift, and ensures an
# ItemConsumer binding exists.
#
# A Flow (not an Agent) is required because the Workflow API's
# `ai_catalog_item_consumer_id` only accepts items of type `flow`
# (ee/app/services/ai/catalog/flows/execute_service.rb).

require 'optparse'

require 'rainbow'

require_relative 'env'
require_relative 'graphql_client'
require_relative 'workspace'

module Gitlab
  module PrinciplesDistiller
    class ProvisionFlow
      DEFAULT_HOST = 'https://gitlab.com'
      DEFAULT_FLOW_NAME = 'Agent Principles Distiller'
      FLOW_DESCRIPTION = 'Distill GitLab development principles from SSOT documentation under ' \
        'doc/development/ into actionable, agent-loadable checklist files.'
      PROMPT_PATH = '.ai/principles/distillation_prompt.md'
      DRY_RUN_FLOW_GID = 'dry-run-flow-gid'

      # Substring of the GraphQL error GitLab returns when the caller lacks
      # `admin_ai_catalog_item` (a Maintainer+ ability). Matched to turn an
      # opaque authorization failure into actionable operator guidance rather
      # than silently escalating the service account's role.
      PERMISSION_DENIED_FRAGMENT = "you don't have permission"

      # Read-only allowlist; names match
      # ee/lib/ai/catalog/built_in_tool_definitions.rb. We curate here
      # rather than rely on agent-side guardrails.
      TOOL_NAMES = %w[
        find_files
        grep
        list_dir
        read_file
        read_files
      ].freeze

      def self.run
        options = parse_options
        new(options).execute
      end

      def self.parse_options
        { dry_run: false }.tap do |options|
          OptionParser.new do |opts|
            opts.banner = 'Usage: gitlab-ai-principles-distiller-provision-flow [options]'
            opts.on('--workspace PATH', 'Path to the repository workspace ' \
              '(defaults to $CI_PROJECT_DIR)') do |path|
              Workspace.path = File.expand_path(path)
            end
            opts.on('--dry-run', 'Print intended actions without mutating the catalog') { options[:dry_run] = true }
          end.parse!
        end
      end

      def initialize(options)
        @dry_run = options[:dry_run]
        @host = ENV.fetch(Env::GITLAB_HOST, DEFAULT_HOST).chomp('/')
        @flow_name = ENV.fetch(Env::CATALOG_FLOW_NAME, DEFAULT_FLOW_NAME)
        @token = ENV[Env::GITLAB_TOKEN]
        @project_path = ENV.fetch(Env::CATALOG_PROJECT) do
          abort Rainbow("ERROR: #{Env::CATALOG_PROJECT} env var is required").red
        end

        abort Rainbow("ERROR: #{Env::GITLAB_TOKEN} env var is required").red if @token.nil? || @token.empty?
      end

      def execute
        puts "Catalog host:   #{@host}"
        puts "Project:        #{@project_path}"
        puts "Flow name:      #{@flow_name}"
        puts Rainbow('[DRY RUN]').cyan if @dry_run

        desired_yaml = build_flow_yaml(load_distillation_prompt)
        project_gid = find_project_gid!(@project_path)

        flow = find_flow
        if flow
          reconcile_flow_version(flow, desired_yaml)
        else
          flow = create_flow(project_gid, desired_yaml)
        end

        consumer = ensure_item_consumer(flow, project_gid)

        puts "\n#{Rainbow('Catalog flow in sync.').green}"
        puts "Flow ID:        #{flow['id']}"
        puts "Consumer ID:    #{consumer['id']}" if consumer
        return unless consumer

        consumer_numeric_id = consumer['id'].to_s.split('/').last
        puts Rainbow(
          "\nExport AGENT_PRINCIPLES_CATALOG_ITEM_CONSUMER_ID=#{consumer_numeric_id} for principles_distiller/sync.rb"
        ).cyan
      end

      private

      def load_distillation_prompt
        path = Workspace.safe_join(PROMPT_PATH)
        abort Rainbow("ERROR: prompt not found at #{path}").red unless File.exist?(path)

        content = File.read(path)
        # Strip the leading authoring-instructions HTML comment.
        content.sub(/\A<!--.*?-->\s*/m, '').strip
      end

      # Single AgentComponent running our distillation prompt; goal is
      # passed at workflow-create time.
      def build_flow_yaml(system_prompt)
        indented_system = indent_block(system_prompt, 8)
        indented_tools  = TOOL_NAMES.map { |t| "    - #{t}" }.join("\n")

        <<~YAML
      version: v1
      environment: ambient
      components:
        - name: distiller
          type: AgentComponent
          prompt_id: distiller_prompt
          inputs:
            - from: context:goal
              as: goal
          toolset:
      #{indented_tools}
          ui_log_events:
            - on_tool_execution_success
            - on_agent_final_answer
            - on_tool_execution_failed
      prompts:
        - prompt_id: distiller_prompt
          name: distiller
          unit_primitives: []
          prompt_template:
            system: |
      #{indented_system}
            user: "{{goal}}"
            placeholder: history
          params:
            timeout: 60
      routers:
        - from: distiller
          to: end
      flow:
        entry_point: distiller
        YAML
      end

      def indent_block(text, spaces)
        pad = ' ' * spaces
        text.each_line.map { |line| line.empty? ? line : "#{pad}#{line}" }.join.chomp
      end

      def graphql_client
        @graphql_client ||= GraphqlClient.new(host: @host, token: @token)
      end

      # One-shot provisioner: any error here is unrecoverable, so abort
      # cleanly rather than retry (contrast Workflow#graphql).
      #
      # `action` names the mutation being attempted (e.g. "release a new
      # flow version"). When the failure is an authorization error, we abort
      # with operator guidance instead of the raw GraphQL message: the
      # scheduled run uses a Developer-role service account, which can read
      # the catalog but cannot create/update flows or consumers (those need
      # the Maintainer+ `admin_ai_catalog_item` ability). Rather than
      # escalate the account, we fail loudly and tell a maintainer how to
      # provision manually.
      def graphql(query, variables = {}, action: nil)
        graphql_client.query(query, variables)
      rescue GraphqlClient::Error => e
        abort permission_denied_guidance(action) if action && permission_denied?(e)

        abort Rainbow(e.message).red
      end

      def permission_denied?(error)
        error.message.include?(PERMISSION_DENIED_FRAGMENT)
      end

      def permission_denied_guidance(action)
        <<~MSG.chomp
          #{Rainbow("ERROR: not authorized to #{action}.").red}

          The AI Catalog flow #{@flow_name.inspect} in #{@project_path} needs to be
          (re)provisioned, but #{Env::GITLAB_TOKEN}'s account lacks the Maintainer-level
          #{Rainbow('admin_ai_catalog_item').yellow} ability required to create or update catalog flows.

          This scheduled job intentionally runs as a Developer-role service account, so
          catalog changes are a manual, maintainer-driven step. To reconcile the flow, a
          project Maintainer should run the provisioner locally with their own token:

            #{Rainbow('export GITLAB_TOKEN=<maintainer-personal-access-token-with-api-scope>').cyan}
            #{Rainbow("export #{Env::CATALOG_PROJECT}=#{@project_path}").cyan}
            #{Rainbow('bundle exec bin/gitlab-ai-principles-distiller-provision-flow \\').cyan}
            #{Rainbow('  --workspace "$(git rev-parse --show-toplevel)"').cyan}

          Re-run this pipeline once the flow is in sync.
        MSG
      end

      def find_project_gid!(full_path)
        vars = { fullPath: full_path }
        data = graphql(<<~GQL, vars)
      query GetProject($fullPath: ID!) {
        project(fullPath: $fullPath) { id }
      }
        GQL

        project = data['project']
        abort Rainbow("ERROR: project not found: #{full_path}").red unless project

        project['id']
      end

      def find_flow
        vars = { search: @flow_name }
        data = graphql(<<~GQL, vars)
      query FindFlow($search: String) {
        aiCatalogItems(search: $search, itemTypes: [FLOW]) {
          nodes {
            id
            name
            project { fullPath }
            latestVersion {
              id
              ... on AiCatalogFlowVersion {
                definition
              }
            }
          }
        }
      }
        GQL

        nodes = data.dig('aiCatalogItems', 'nodes') || []
        nodes.find { |n| n['name'] == @flow_name && n.dig('project', 'fullPath') == @project_path }
      end

      def create_flow(project_gid, yaml_definition)
        if @dry_run
          puts Rainbow("[DRY RUN] Would create flow #{@flow_name.inspect} in #{@project_path}").cyan
          return { 'id' => DRY_RUN_FLOW_GID, 'latestVersion' => nil }
        end

        puts Rainbow("Creating flow #{@flow_name.inspect} in #{@project_path}...").yellow

        variables = {
          input: {
            name: @flow_name,
            description: FLOW_DESCRIPTION,
            projectId: project_gid,
            public: false,
            release: true,
            definition: yaml_definition
          }
        }
        data = graphql(<<~GQL, variables, action: 'create the catalog flow')
      mutation CreateFlow($input: AiCatalogFlowCreateInput!) {
        aiCatalogFlowCreate(input: $input) {
          item { id name latestVersion { id } }
          errors
        }
      }
        GQL

        payload = data['aiCatalogFlowCreate']
        abort Rainbow("ERROR creating flow: #{payload['errors']}").red if payload['errors']&.any?

        payload['item']
      end

      def reconcile_flow_version(flow, desired_yaml)
        version = flow['latestVersion']
        current_yaml = version&.dig('definition')

        if current_yaml == desired_yaml
          puts Rainbow('Flow definition already up to date.').green
          return
        end

        if current_yaml
          puts Rainbow('Flow definition drift detected.').yellow
          diff_summary(current_yaml, desired_yaml)
        end

        if @dry_run
          puts Rainbow('[DRY RUN] Would release a new flow version.').cyan
          return
        end

        puts 'Releasing new flow version...'
        variables = {
          input: {
            id: flow['id'],
            definition: desired_yaml,
            versionBump: 'PATCH',
            release: true
          }
        }
        data = graphql(<<~GQL, variables, action: 'release a new flow version')
      mutation UpdateFlow($input: AiCatalogFlowUpdateInput!) {
        aiCatalogFlowUpdate(input: $input) {
          item { id latestVersion { id } }
          errors
        }
      }
        GQL

        payload = data['aiCatalogFlowUpdate']
        abort Rainbow("ERROR updating flow: #{payload['errors']}").red if payload['errors']&.any?

        puts Rainbow("Flow updated. New latestVersion: #{payload.dig('item', 'latestVersion', 'id')}").green
      end

      def ensure_item_consumer(flow, project_gid)
        # Dry-run flow has a placeholder GID; short-circuit the lookup
        # that would fail GraphQL validation.
        if @dry_run && flow['id'] == DRY_RUN_FLOW_GID
          puts Rainbow('[DRY RUN] Would create ItemConsumer for the flow in the project.').cyan
          return
        end

        lookup_vars = { id: flow['id'], projectId: project_gid }
        existing = graphql(<<~GQL, lookup_vars)
      query ExistingConsumer($id: AiCatalogItemID!, $projectId: ProjectID!) {
        aiCatalogItem(id: $id) {
          configurationForProject(projectId: $projectId) { id }
        }
      }
        GQL

        consumer = existing.dig('aiCatalogItem', 'configurationForProject')
        if consumer
          puts Rainbow("ItemConsumer already exists: #{consumer['id']}").green
          return consumer
        end

        if @dry_run
          puts Rainbow('[DRY RUN] Would create ItemConsumer for the flow in the project.').cyan
          return
        end

        puts 'Creating ItemConsumer...'

        create_vars = { input: { itemId: flow['id'], target: { projectId: project_gid } } }
        data = graphql(<<~GQL, create_vars, action: 'create the flow ItemConsumer binding')
      mutation CreateConsumer($input: AiCatalogItemConsumerCreateInput!) {
        aiCatalogItemConsumerCreate(input: $input) {
          itemConsumer { id }
          errors
        }
      }
        GQL

        payload = data['aiCatalogItemConsumerCreate']
        abort Rainbow("ERROR creating ItemConsumer: #{payload['errors']}").red if payload['errors']&.any?

        puts Rainbow("ItemConsumer created: #{payload.dig('itemConsumer', 'id')}").green
        payload['itemConsumer']
      end

      def diff_summary(old_text, new_text)
        old_size = old_text.to_s.bytesize
        new_size = new_text.to_s.bytesize
        puts Rainbow("  current: #{old_size} bytes  desired: #{new_size} bytes  delta: #{new_size - old_size}").faint
      end
    end
  end
end
