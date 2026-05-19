# frozen_string_literal: true

module Projects
  module Settings
    class BranchRulesController < Projects::ApplicationController
      before_action :authorize_read_branch_rule!

      before_action do
        push_frontend_feature_flag(:skip_empty_access_levels_in_branch_rules, @project)
      end

      feature_category :source_code_management

      def index; end
    end
  end
end

Projects::Settings::BranchRulesController.prepend_mod
