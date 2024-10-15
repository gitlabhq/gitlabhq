# frozen_string_literal: true

module Mutations
  module DesignManagement
    class Upload < Base
      graphql_name "DesignManagementUpload"

      argument :files, [ApolloUploadServer::Upload],
        required: true,
        description: "Files to upload."

      authorize :create_design

      field :designs, [Types::DesignManagement::DesignType],
        null: false,
        description: "Designs that were uploaded by the mutation."

      field :skipped_designs, [Types::DesignManagement::DesignType],
        null: false,
        description: "Any designs that were skipped from the upload due to there " \
          "being no change to their content since their last version"

      def resolve(project_path:, iid:, files:)
        issue = authorized_find!(project_path: project_path, iid: iid)
        project = issue.project

        result = ::DesignManagement::SaveDesignsService.new(project, current_user, issue: issue, files: files)
                   .execute

        {
          designs: Array.wrap(result[:designs]),
          skipped_designs: Array.wrap(result[:skipped_designs]),
          errors: Array.wrap(result[:message])
        }
      end
    end
  end
end
