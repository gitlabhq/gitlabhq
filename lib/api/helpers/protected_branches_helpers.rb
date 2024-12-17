# frozen_string_literal: true

module API
  module Helpers
    module ProtectedBranchesHelpers
      extend ActiveSupport::Concern
      extend Grape::API::Helpers

      def authorize_create_protected_branch!
        authorize!(:create_protected_branch, user_project)
      end

      def authorize_update_protected_branch!(protected_branch)
        authorize!(:update_protected_branch, protected_branch)
      end

      def authorize_destroy_protected_branch!(protected_branch)
        authorize!(:destroy_protected_branch, protected_branch)
      end

      params :optional_params_ee do
      end
    end
  end
end

API::Helpers::ProtectedBranchesHelpers.prepend_mod_with('API::Helpers::ProtectedBranchesHelpers')
