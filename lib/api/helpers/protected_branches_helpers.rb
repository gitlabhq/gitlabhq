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

      params :optional_params_ce do
        optional :allowed_to_push, type: Array[JSON],
          desc: 'Array of deploy keys allowed to push to protected branches' do
          optional :deploy_key_id, type: Integer, desc: 'ID of a deploy key'
        end
      end

      params :optional_params_ee do
      end

      params :optional_params do
        use :optional_params_ce
        use :optional_params_ee
      end
    end
  end
end

API::Helpers::ProtectedBranchesHelpers.prepend_mod_with('API::Helpers::ProtectedBranchesHelpers')
