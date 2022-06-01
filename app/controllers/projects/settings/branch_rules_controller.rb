# frozen_string_literal: true

module Projects
  module Settings
    class BranchRulesController < Projects::ApplicationController
      before_action :authorize_admin_project!

      feature_category :source_code_management

      def index
        render_404 unless Feature.enabled?(:branch_rules, project)
      end
    end
  end
end
