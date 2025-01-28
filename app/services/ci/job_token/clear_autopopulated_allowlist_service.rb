# frozen_string_literal: true

module Ci
  module JobToken
    class ClearAutopopulatedAllowlistService
      def initialize(project, user)
        @project = project
        @user = user
      end

      def execute
        raise Gitlab::Access::AccessDeniedError unless authorized?

        allowlist = Ci::JobToken::Allowlist.new(@project)

        ApplicationRecord.transaction do
          allowlist.project_links.autopopulated.delete_all
          allowlist.group_links.autopopulated.delete_all
        end

        ServiceResponse.success
      end

      private

      def authorized?
        @user.can?(:admin_project, @project)
      end
    end
  end
end
