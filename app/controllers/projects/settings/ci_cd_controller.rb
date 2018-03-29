module Projects
  module Settings
    class CiCdController < Projects::ApplicationController
      before_action :authorize_admin_pipeline!

      def show
        define_runners_variables
        define_secret_variables
        define_triggers_variables
        define_badges_variables
        define_auto_devops_variables
      end

      def reset_cache
        if ResetProjectCacheService.new(@project, current_user).execute
          respond_to do |format|
            format.json { head :ok }
          end
        else
          respond_to do |format|
            format.json { head :bad_request }
          end
        end
      end

      private

      def define_runners_variables
        @project_runners = @project.runners.ordered
        @assignable_runners = current_user.ci_authorized_runners
          .assignable_for(project).ordered.page(params[:page]).per(20)
        @shared_runners = ::Ci::Runner.shared.active
        @shared_runners_count = @shared_runners.count(:all)
      end

      def define_secret_variables
        @variable = ::Ci::Variable.new(project: project)
          .present(current_user: current_user)
        @variables = project.variables.order_key_asc
          .map { |variable| variable.present(current_user: current_user) }
      end

      def define_triggers_variables
        @triggers = @project.triggers
        @trigger = ::Ci::Trigger.new
      end

      def define_badges_variables
        @ref = params[:ref] || @project.default_branch || 'master'

        @badges = [Gitlab::Badge::Pipeline::Status,
                   Gitlab::Badge::Coverage::Report]

        @badges.map! do |badge|
          badge.new(@project, @ref).metadata
        end
      end

      def define_auto_devops_variables
        @auto_devops = @project.auto_devops || ProjectAutoDevops.new
      end
    end
  end
end
