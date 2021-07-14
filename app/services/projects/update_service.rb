# frozen_string_literal: true

module Projects
  class UpdateService < BaseService
    include UpdateVisibilityLevel
    include ValidatesClassificationLabel

    ValidationError = Class.new(StandardError)

    def execute
      build_topics
      remove_unallowed_params
      validate!

      ensure_wiki_exists if enabling_wiki?

      if changing_repository_storage?
        storage_move = project.repository_storage_moves.build(
          source_storage_name: project.repository_storage,
          destination_storage_name: params.delete(:repository_storage)
        )
        storage_move.schedule
      end

      yield if block_given?

      validate_classification_label(project, :external_authorization_classification_label)

      # If the block added errors, don't try to save the project
      return update_failed! if project.errors.any?

      if project.update(params.except(:default_branch))
        after_update

        success
      else
        update_failed!
      end
    rescue ValidationError => e
      error(e.message)
    end

    def run_auto_devops_pipeline?
      return false if project.repository.gitlab_ci_yml || !project.auto_devops&.previous_changes&.include?('enabled')

      project.auto_devops_enabled?
    end

    private

    def validate!
      unless valid_visibility_level_change?(project, params[:visibility_level])
        raise ValidationError, s_('UpdateProject|New visibility level not allowed!')
      end

      if renaming_project_with_container_registry_tags?
        raise ValidationError, s_('UpdateProject|Cannot rename project because it contains container registry tags!')
      end

      validate_default_branch_change
    end

    def validate_default_branch_change
      return unless changing_default_branch?

      previous_default_branch = project.default_branch

      if project.change_head(params[:default_branch])
        params[:previous_default_branch] = previous_default_branch

        after_default_branch_change(previous_default_branch)
      else
        raise ValidationError, s_("UpdateProject|Could not set the default branch")
      end
    end

    def after_default_branch_change(previous_default_branch)
      # overridden by EE module
    end

    def remove_unallowed_params
      params.delete(:emails_disabled) unless can?(current_user, :set_emails_disabled, project)
    end

    def after_update
      todos_features_changes = %w(
        issues_access_level
        merge_requests_access_level
        repository_access_level
      )
      project_changed_feature_keys = project.project_feature.previous_changes.keys

      if project.visibility_level_previous_changes && project.private?
        # don't enqueue immediately to prevent todos removal in case of a mistake
        TodosDestroyer::ConfidentialIssueWorker.perform_in(Todo::WAIT_FOR_DELETE, nil, project.id)
        TodosDestroyer::ProjectPrivateWorker.perform_in(Todo::WAIT_FOR_DELETE, project.id)
      elsif (project_changed_feature_keys & todos_features_changes).present?
        TodosDestroyer::PrivateFeaturesWorker.perform_in(Todo::WAIT_FOR_DELETE, project.id)
      end

      if project.previous_changes.include?('path')
        after_rename_service(project).execute
      else
        system_hook_service.execute_hooks_for(project, :update)
      end

      update_pages_config if changing_pages_related_config?
    end

    def after_rename_service(project)
      AfterRenameService.new(project, path_before: project.path_before_last_save, full_path_before: project.full_path_before_last_save)
    end

    def changing_pages_related_config?
      changing_pages_https_only? || changing_pages_access_level?
    end

    def update_failed!
      model_errors = project.errors.full_messages.to_sentence
      error_message = model_errors.presence || s_('UpdateProject|Project could not be updated!')

      error(error_message)
    end

    def renaming_project_with_container_registry_tags?
      new_path = params[:path]

      new_path && new_path != project.path &&
        project.has_container_registry_tags?
    end

    def changing_default_branch?
      new_branch = params[:default_branch]

      new_branch && project.repository.exists? &&
        new_branch != project.default_branch
    end

    def enabling_wiki?
      return false if project.wiki_enabled?

      params.dig(:project_feature_attributes, :wiki_access_level).to_i > ProjectFeature::DISABLED
    end

    def changing_pages_access_level?
      params.dig(:project_feature_attributes, :pages_access_level)
    end

    def ensure_wiki_exists
      return if project.create_wiki

      log_error("Could not create wiki for #{project.full_name}")
      Gitlab::Metrics.counter(:wiki_can_not_be_created_total, 'Counts the times we failed to create a wiki').increment
    end

    def update_pages_config
      return unless project.pages_deployed?

      PagesUpdateConfigurationWorker.perform_async(project.id)
    end

    def changing_pages_https_only?
      project.previous_changes.include?(:pages_https_only)
    end

    def changing_repository_storage?
      new_repository_storage = params[:repository_storage]

      new_repository_storage && project.repository.exists? &&
        project.repository_storage != new_repository_storage &&
        can?(current_user, :change_repository_storage, project)
    end

    def build_topics
      topics = params.delete(:topics)
      tag_list = params.delete(:tag_list)
      topic_list = topics || tag_list

      params[:topic_list] ||= topic_list if topic_list
    end
  end
end

Projects::UpdateService.prepend_mod_with('Projects::UpdateService')
