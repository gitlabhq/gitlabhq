module Projects
  module Settings
    class CiCdController < Projects::ApplicationController
      before_action :authorize_admin_pipeline!
      before_action :define_variables

      def show
      end

      def update
        Projects::UpdateService.new(project, current_user, update_params).tap do |service|
          result = service.execute
          if result[:status] == :success
            flash[:notice] = "Pipelines settings for '#{@project.name}' were successfully updated."

            run_autodevops_pipeline(service)

            if service.auto_devops_conflicts_custom_yml?
              flash[:warning] = "The project must remove the custom CI config file to use the Auto DevOps pipeline configuration."
            end

            redirect_to project_settings_ci_cd_path(@project)
          else
            render 'show'
          end
        end
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

      def update_params
        params.require(:project).permit(
          :runners_token, :builds_enabled, :build_allow_git_fetch,
          :build_timeout_human_readable, :build_coverage_regex, :public_builds,
          :auto_cancel_pending_pipelines, :ci_config_path,
          auto_devops_attributes: [:id, :domain, :enabled]
        )
      end

      def run_autodevops_pipeline(service)
        return unless service.run_auto_devops_pipeline?

        if @project.empty_repo?
          flash[:warning] = "This repository is currently empty. A new Auto DevOps pipeline will be created after a new file has been pushed to a branch."
          return
        end

        CreatePipelineWorker.perform_async(project.id, current_user.id, project.default_branch, :web, ignore_skip_ci: true, save_on_errors: false)
        flash[:success] = "A new Auto DevOps pipeline has been created, go to <a href=\"#{project_pipelines_path(@project)}\">Pipelines page</a> for details".html_safe
      end

      def define_variables
        define_runners_variables
        define_secret_variables
        define_triggers_variables
        define_badges_variables
        define_auto_devops_variables
      end

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
