# frozen_string_literal: true

module Projects
  module Settings
    class BranchRulesController < Projects::ApplicationController
      before_action :authorize_admin_project!
      before_action do
        push_frontend_feature_flag(:edit_branch_rules, @project)
      end

      feature_category :source_code_management

      def index; end
    end
  end
end

Projects::Settings::BranchRulesController.prepend_mod
