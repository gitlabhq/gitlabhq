# frozen_string_literal: true

module Mutations
  module DesignManagement
    class Delete < Base
      Errors = ::Gitlab::Graphql::Errors

      graphql_name "DesignManagementDelete"

      argument :filenames, [GraphQL::Types::String],
               required: true,
               description: "The filenames of the designs to delete.",
               prepare: ->(names, _ctx) do
                 names.presence || (raise Errors::ArgumentError, 'no filenames')
               end

      field :version, Types::DesignManagement::VersionType,
            null: true, # null on error
            description: 'The new version in which the designs are deleted.'

      authorize :destroy_design

      def resolve(project_path:, iid:, filenames:)
        issue = authorized_find!(project_path: project_path, iid: iid)
        project = issue.project
        designs = resolve_designs(issue, filenames)

        result = ::DesignManagement::DeleteDesignsService
          .new(project, current_user, issue: issue, designs: designs)
          .execute

        {
          version: result[:version],
          errors: Array.wrap(result[:message])
        }
      end

      private

      # Here we check that:
      #  * we find exactly as many designs as filenames
      def resolve_designs(issue, filenames)
        designs = issue.design_collection.designs_by_filename(filenames)

        validate_all_were_found!(designs, filenames)

        designs
      end

      def validate_all_were_found!(designs, filenames)
        found_filenames = designs.map(&:filename)
        missing = filenames.difference(found_filenames)

        if missing.present?
          raise Errors::ArgumentError, <<~MSG
            Not all the designs you named currently exist.
            The following filenames were not found:
            #{missing.join(', ')}

            They may have already been deleted.
          MSG
        end
      end
    end
  end
end
