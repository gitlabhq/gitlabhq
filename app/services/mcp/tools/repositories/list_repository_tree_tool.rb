# frozen_string_literal: true

module Mcp
  module Tools
    module Repositories
      class ListRepositoryTreeTool < Mcp::Tools::Base::GraphqlTool
        include Mcp::Tools::Concerns::ResourceFinder
        include Mcp::Tools::Concerns::UrlParser

        PARENT_PARAMS = %i[url project_id].freeze
        ENTRY_CONNECTIONS = %w[trees blobs submodules].freeze

        register_version VERSIONS[:v0_1_0], {
          graphql_operation: load_graphql('repositories/list_repository_tree.query.graphql'),
          operation_name: 'project'
        }

        def build_variables
          {
            fullPath: project.full_path,
            path: normalized_path,
            ref: params[:ref],
            recursive: params[:recursive],
            after: params[:after]
          }.compact
        end

        protected

        def build_variables_v0_1_0
          build_variables
        end

        private

        # Gitaly resolves paths from the repository root, so a leading slash finds nothing.
        def normalized_path
          params[:path]&.sub(%r{\A/+}, '')
        end

        def project
          @project ||= resolve_project
        end

        def resolve_project
          provided = PARENT_PARAMS.select { |key| params[key].present? }

          raise ArgumentError, 'Provide exactly one of: url or project_id' unless provided.one?

          identifier = provided.first == :url ? parse_parent_url(params[:url])[:path] : params[:project_id]

          project = find_project!(identifier)
          authorize_read_project!(project, identifier)
          project
        end

        # Reuse find_project!'s wording so a private project the user cannot read is
        # indistinguishable from one that does not exist, preventing enumeration.
        def authorize_read_project!(project, identifier)
          return if ::Ability.allowed?(current_user, :read_project, project)

          raise ::Gitlab::Access::AccessDeniedError, "Project '#{identifier}' not found or inaccessible"
        end

        def process_result(result)
          return resource_not_found_error if resource_not_found?(result)

          processed_result = super
          return processed_result if processed_result[:isError]

          repository = processed_result[:structuredContent]['repository']
          return repository_access_error if repository.nil?

          tree = repository['paginatedTree']
          return success(empty_payload) if tree.nil? # the repository is empty

          payload = build_payload(tree)
          # Git tracks no empty directories, so an empty first page means the ref or path did not resolve.
          # A later page can legitimately be empty, so this only applies when there is no cursor.
          return entries_not_found_error if payload['entries'].empty? && params[:after].blank?

          success(payload)
        end

        def build_payload(tree)
          entries = tree['nodes'].flat_map do |node|
            ENTRY_CONNECTIONS.flat_map { |connection| node.dig(connection, 'nodes') || [] }
          end

          entries = entries.map { |entry| entry.merge('id' => unwrap_id(entry['id'])) }

          { 'entries' => entries, 'pageInfo' => tree['pageInfo'] }
        end

        # GraphQL wraps the Git object ID in a global ID (gid://gitlab/...TreeEntry/<oid>).
        def unwrap_id(gid)
          ::GlobalID.parse(gid)&.model_id || gid
        end

        def empty_payload
          { 'entries' => [], 'pageInfo' => { 'hasNextPage' => false, 'endCursor' => nil } }
        end

        def success(payload)
          formatted_content = [{ type: 'text', text: Gitlab::Json.dump(payload) }]
          ::Mcp::Tools::Base::Response.success(formatted_content, payload)
        end

        def resource_not_found_error
          ::Mcp::Tools::Base::Response.error(
            'Project not found: it does not exist or you do not have access to it.'
          )
        end

        def repository_access_error
          ::Mcp::Tools::Base::Response.error(
            "The repository of project '#{project.full_path}' is not available: repository access is " \
              'disabled, or you do not have permission to read it.'
          )
        end

        def entries_not_found_error
          return ref_not_found_error unless ref_exists?

          path_not_found_error
        end

        def ref_exists?
          params[:ref].blank? || project.repository.commit(params[:ref]).present?
        end

        def ref_not_found_error
          ::Mcp::Tools::Base::Response.error(
            "Ref '#{params[:ref]}' not found. Provide an existing branch name, tag name, or commit SHA, " \
              'or use HEAD for the default branch.'
          )
        end

        def path_not_found_error
          ::Mcp::Tools::Base::Response.error(
            "Path '#{params[:path]}' not found at ref '#{params[:ref].presence || 'HEAD'}': it does not exist " \
              'or is a file, not a directory. Provide a directory path relative to the repository root, ' \
              'or use get_repository_file to read a file.'
          )
        end
      end
    end
  end
end
