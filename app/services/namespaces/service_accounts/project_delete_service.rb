# frozen_string_literal: true

module Namespaces
  module ServiceAccounts
    class ProjectDeleteService < BaseDeleteService
      extend ::Gitlab::Utils::Override

      private

      override :user_provisioned_resource
      def user_provisioned_resource
        user.provisioned_by_project
      end
    end
  end
end
