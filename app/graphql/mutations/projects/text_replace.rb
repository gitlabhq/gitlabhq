# frozen_string_literal: true

module Mutations
  module Projects
    class TextReplace < BaseMutation
      graphql_name 'projectTextReplace'

      include FindsProject

      UNSUPPORTED_REPLACEMENT_PREFIX = %r{(?:regex|glob):}
      SUPPORTED_REPLACEMENT_PREFIX = %r{literal:}
      EMPTY_REPLACEMENTS_ARG_ERROR = <<~ERROR
        Argument 'replacements' on InputObject 'projectTextReplaceInput' is required. Expected type [String!]!
      ERROR
      UNSUPPORTED_REPLACEMENTS_ARG_ERROR = <<~ERROR
        Argument 'replacements' on InputObject 'projectTextReplaceInput' does not support 'regex:' or 'glob:' values.
      ERROR

      authorize :owner_access

      argument :project_path, GraphQL::Types::ID,
        required: true,
        description: 'Full path of the project to replace.'

      argument :replacements, [GraphQL::Types::String],
        required: true,
        description: 'List of text patterns to replace project-wide.',
        prepare: ->(replacements, _ctx) do
          replacements.reject!(&:blank?)

          raise(GraphQL::ExecutionError, EMPTY_REPLACEMENTS_ARG_ERROR) if replacements.empty?

          if replacements.any? { |r| r.starts_with?(UNSUPPORTED_REPLACEMENT_PREFIX) }
            raise(GraphQL::ExecutionError, UNSUPPORTED_REPLACEMENTS_ARG_ERROR)
          end

          replacements.map { |r| r.starts_with?(SUPPORTED_REPLACEMENT_PREFIX) ? r : "literal:#{r}" }
        end

      def resolve(project_path:, replacements:)
        project = authorized_find!(project_path)

        begin
          project.set_repository_read_only!
          client = Gitlab::GitalyClient::CleanupService.new(project.repository)
          client.rewrite_history(redactions: replacements)

          audit_replacements(project)

          { errors: [] }
        ensure
          project.set_repository_writable!
        end
      end

      def audit_replacements(project)
        context = {
          name: 'project_text_replacement',
          author: current_user,
          scope: project,
          target: project,
          message: 'Project text replaced'
        }

        ::Gitlab::Audit::Auditor.audit(context)
      end
    end
  end
end
