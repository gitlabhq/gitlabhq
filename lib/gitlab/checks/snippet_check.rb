# frozen_string_literal: true

module Gitlab
  module Checks
    class SnippetCheck < BaseSingleChecker
      ERROR_MESSAGES = {
        create_delete_branch: 'You can not create or delete branches.'
      }.freeze

      ATTRIBUTES = %i[oldrev newrev ref branch_name tag_name logger].freeze
      attr_reader(*ATTRIBUTES)

      def initialize(change, default_branch:, root_ref:, logger:)
        @oldrev, @newrev, @ref = change.values_at(:oldrev, :newrev, :ref)
        @branch_name = Gitlab::Git.branch_name(@ref)
        @tag_name = Gitlab::Git.tag_name(@ref)

        @default_branch = default_branch
        @root_ref = root_ref
        @logger = logger
        @logger.append_message("Running checks for ref: #{@branch_name || @tag_name}")
      end

      def validate!
        if !@default_branch || creation? || deletion?
          raise GitAccess::ForbiddenError, ERROR_MESSAGES[:create_delete_branch]
        end

        true
      rescue GitAccess::ForbiddenError => e
        Gitlab::ErrorTracking.log_exception(e, default_branch: @default_branch, branch_name: @branch_name, creation: creation?, deletion: deletion?)

        raise e
      end

      private

      # If the `root_ref` is not present means that this is the first commit to the
      # repository and when the default branch is going to be created.
      # We allow the first branch creation no matter the name because
      # it can be even an imported snippet from an instance with a different
      # default branch.
      def creation?
        super && @root_ref && (@branch_name != @default_branch)
      end
    end
  end
end
