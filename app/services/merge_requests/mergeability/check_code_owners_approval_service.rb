# frozen_string_literal: true

module MergeRequests
  module Mergeability
    class CheckCodeOwnersApprovalService < CheckBaseService
      include Gitlab::Utils::StrongMemoize

      set_identifier :code_owners_approval
      set_description 'Checks whether required CODEOWNERS have approved'

      def execute
        return inactive if codeowners_blob.nil?
        return success  if required_owners.empty?

        if missing_owners.empty?
          success
        else
          failure(missing_owners: missing_owners)
        end
      end

      def skip?
        params[:skip_code_owners_check].present?
      end

      def cacheable?
        false
      end

      private

      def project
        merge_request.project
      end

      def codeowners_blob
        project.repository.blob_at_branch(merge_request.target_branch, 'CODEOWNERS') ||
          project.repository.blob_at_branch(merge_request.target_branch, '.gitlab/CODEOWNERS') ||
          project.repository.blob_at_branch(merge_request.target_branch, 'docs/CODEOWNERS')
      end
      strong_memoize_attr :codeowners_blob

      def parser
        ::Gitlab::CodeOwners::Parser.new(codeowners_blob.data)
      end
      strong_memoize_attr :parser

      def changed_paths
        merge_request.modified_paths
      end
      strong_memoize_attr :changed_paths

      def required_owners
        changed_paths.flat_map { |path| parser.owners_for_path(path) }.uniq
      end
      strong_memoize_attr :required_owners

      def approved_owner_tokens
        merge_request.approved_by_users.flat_map do |user|
          ["@#{user.username}", user.email]
        end.to_set
      end
      strong_memoize_attr :approved_owner_tokens

      def missing_owners
        required_owners.reject { |owner| approved_owner_tokens.include?(owner) }
      end
      strong_memoize_attr :missing_owners
    end
  end
end
