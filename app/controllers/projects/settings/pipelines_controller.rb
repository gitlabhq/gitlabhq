module Projects
  module Settings
    class PipelinesController < Projects::ApplicationController
      before_action :authorize_admin_pipeline!
      
      def show
        # runners
        @project_runners = @project.runners.ordered
        @assignable_runners = current_user.ci_authorized_runners.
          assignable_for(project).ordered.page(params[:page]).per(20)
        @shared_runners = Ci::Runner.shared.active
        @shared_runners_count = @shared_runners.count(:all)
        # variables
        @variable = Ci::Variable.new
        # triggers
        @triggers = @project.triggers
        @trigger = Ci::Trigger.new
        # pipelines
        @ref = params[:ref] || @project.default_branch || 'master'

        @badges = [Gitlab::Badge::Build::Status,
                   Gitlab::Badge::Coverage::Report]

        @badges.map! do |badge|
          badge.new(@project, @ref).metadata
        end
      end
    end
  end
end
