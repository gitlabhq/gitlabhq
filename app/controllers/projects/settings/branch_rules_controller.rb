# frozen_string_literal: true

module Projects
  module Settings
    class BranchRulesController < Projects::ApplicationController
      before_action :authorize_admin_project!

      feature_category :source_code_management

      def index; end
    end
  end
end
