# frozen_string_literal: true

module Projects
  module Settings
    class CiCdController < Projects::ApplicationController
      include RunnerSetupScripts

      NUMBER_OF_RUNNERS_PER_PAGE = 20

      layout 'project_settings'
      before_action :authorize_admin_pipeline!
      before_action :check_builds_available!
      before_action :define_variables

      before_action do
        push_frontend_feature_flag(:ci_variables_pages, current_user)
        push_frontend_feature_flag(:ci_limit_environment_scope, @project)
        push_frontend_feature_flag(:create_runner_workflow_for_namespace, @project.namespace)
        push_frontend_feature_flag(:frozen_outbound_job_token_scopes, @project)
        push_frontend_feature_flag(:frozen_outbound_job_token_scopes_override, @project)
      end

      helper_method :highlight_badge

      feature_category :continuous_integration
      urgency :low

      def show
        @entity = :project
        @variable_limit = ::Plan.default.actual_limits.project_ci_variables

        triggers = ::Ci::TriggerSerializer.new.represent(
          @project.triggers, current_user: current_user, project: @project
        )

        @triggers_json = Gitlab::Json.dump(triggers)

        render
      end

      def update
        Projects::UpdateService.new(project, current_user, update_params).tap do |service|
          result = service.execute
          if result[:status] == :success
            flash[:toast] = _("Pipelines settings for '%{project_name}' were successfully updated.") % { project_name: @project.name }

            run_autodevops_pipeline(service)

            redirect_to project_settings_ci_cd_path(@project)
          else
            redirect_to project_settings_ci_cd_path(@project), alert: result[:message]
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

      def reset_registration_token
        ::Ci::Runners::ResetRegistrationTokenService.new(@project, current_user).execute

        flash[:toast] = _("New runners registration token has been generated!")
        redirect_to namespace_project_settings_ci_cd_path
      end

      def runner_setup_scripts
        private_runner_setup_scripts
      end

      private

      def highlight_badge(name, content, language = nil)
        Gitlab::Highlight.highlight(name, content, language: language)
      end

      def update_params
        params.require(:project).permit(*permitted_project_params)
      end

      def permitted_project_params
        [
          :runners_token, :builds_enabled, :build_allow_git_fetch,
          :build_timeout_human_readable, :public_builds, :ci_separated_caches,
          :auto_cancel_pending_pipelines, :ci_config_path, :auto_rollback_enabled,
          auto_devops_attributes: [:id, :domain, :enabled, :deploy_strategy],
          ci_cd_settings_attributes: [:default_git_depth, :forward_deployment_enabled]
        ].tap do |list|
          list << :max_artifacts_size if can?(current_user, :update_max_artifacts_size, project)
        end
      end

      def run_autodevops_pipeline(service)
        return unless service.run_auto_devops_pipeline?

        if @project.empty_repo?
          flash[:notice] = _("This repository is currently empty. A new Auto DevOps pipeline will be created after a new file has been pushed to a branch.")
          return
        end

        # rubocop:disable CodeReuse/Worker
        CreatePipelineWorker.perform_async(project.id, current_user.id, project.default_branch, :web, ignore_skip_ci: true, save_on_errors: false)
        # rubocop:enable CodeReuse/Worker

        flash[:toast] = _("A new Auto DevOps pipeline has been created, go to the Pipelines page for details")
      end

      def define_variables
        define_runners_variables
        define_ci_variables
        define_triggers_variables
        define_badges_variables
        define_auto_devops_variables
      end

      def define_runners_variables
        @project_runners = @project.runners.ordered.page(params[:project_page]).per(NUMBER_OF_RUNNERS_PER_PAGE).with_tags

        @assignable_runners = current_user
          .ci_owned_runners
          .assignable_for(project)
          .ordered
          .page(params[:specific_page]).per(NUMBER_OF_RUNNERS_PER_PAGE)
          .with_tags

        active_shared_runners = ::Ci::Runner.instance_type.active
        @shared_runners_count = active_shared_runners.count
        @shared_runners = active_shared_runners.page(params[:shared_runners_page]).per(NUMBER_OF_RUNNERS_PER_PAGE).with_tags

        parent_group_runners = ::Ci::Runner.belonging_to_parent_groups_of_project(@project.id)
        @group_runners_count = parent_group_runners.count
        @group_runners = parent_group_runners.page(params[:group_runners_page]).per(NUMBER_OF_RUNNERS_PER_PAGE).with_tags
      end

      def define_ci_variables
        @variable = ::Ci::Variable.new(project: project)
          .present(current_user: current_user)
        @variables = project.variables.order_key_asc
          .map { |variable| variable.present(current_user: current_user) }
      end

      def define_triggers_variables
        @triggers = @project.triggers
          .present(current_user: current_user)

        @trigger = ::Ci::Trigger.new
          .present(current_user: current_user)
      end

      def define_badges_variables
        @ref = params[:ref] || @project.default_branch_or_main

        @badges = [Gitlab::Ci::Badge::Pipeline::Status,
                   Gitlab::Ci::Badge::Coverage::Report]

        @badges.map! do |badge|
          badge.new(@project, @ref).metadata
        end

        @badges.append(Gitlab::Ci::Badge::Release::LatestRelease.new(@project, current_user).metadata)
      end

      def define_auto_devops_variables
        @auto_devops = @project.auto_devops || ProjectAutoDevops.new
      end
    end
  end
end

Projects::Settings::CiCdController.prepend_mod_with('Projects::Settings::CiCdController')
