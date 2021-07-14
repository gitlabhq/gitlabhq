# frozen_string_literal: true

module Snippets
  class UpdateService < Snippets::BaseService
    COMMITTABLE_ATTRIBUTES = %w(file_name content).freeze

    UpdateError = Class.new(StandardError)

    # NOTE: For Snippets::UpdateService, we default the spam_params to nil, because spam_checking is not
    # necessary in many cases, and we don't want every caller to have to explicitly pass it as nil
    # to disable spam checking.
    def initialize(project:, current_user: nil, params: {}, spam_params: nil)
      super(project: project, current_user: current_user, params: params)
      @spam_params = spam_params
    end

    def execute(snippet)
      return invalid_params_error(snippet) unless valid_params?

      if visibility_changed?(snippet) && !visibility_allowed?(visibility_level)
        return forbidden_visibility_error(snippet)
      end

      update_snippet_attributes(snippet)

      Spam::SpamActionService.new(
        spammable: snippet,
        spam_params: spam_params,
        user: current_user,
        action: :update
      ).execute

      if save_and_commit(snippet)
        Gitlab::UsageDataCounters::SnippetCounter.count(:update)

        ServiceResponse.success(payload: { snippet: snippet })
      else
        snippet_error_response(snippet, 400)
      end
    end

    private

    attr_reader :spam_params

    def visibility_changed?(snippet)
      visibility_level && visibility_level.to_i != snippet.visibility_level
    end

    def update_snippet_attributes(snippet)
      # We can remove the following condition once
      # https://gitlab.com/gitlab-org/gitlab/-/issues/217801
      # is implemented.
      # Once we can perform different operations through this service
      # we won't need to keep track of the `content` and `file_name` fields
      #
      # If the repository does not exist we don't need to update `params`
      # because we need to commit the information from the database
      if snippet_actions.any? && snippet.repository_exists?
        params[:content] = snippet_actions[0].content if snippet_actions[0].content
        params[:file_name] = snippet_actions[0].file_path
      end

      snippet.assign_attributes(params)
    end

    def save_and_commit(snippet)
      return false unless snippet.save

      # If the updated attributes does not need to update
      # the repository we can just return
      return true unless committable_attributes?

      unless snippet.repository_exists?
        create_repository_for(snippet)
        create_first_commit_using_db_data(snippet)
      end

      create_commit(snippet)

      true
    rescue StandardError => e
      # Restore old attributes but re-assign changes so they're not lost
      unless snippet.previous_changes.empty?
        snippet.previous_changes.each { |attr, value| snippet[attr] = value[0] }
        snippet.save

        snippet.assign_attributes(params)
      end

      add_snippet_repository_error(snippet: snippet, error: e)

      Gitlab::ErrorTracking.log_exception(e, service: 'Snippets::UpdateService')

      # If the commit action failed we remove it because
      # we don't want to leave empty repositories
      # around, to allow cloning them.
      delete_repository(snippet) if repository_empty?(snippet)

      false
    end

    def create_repository_for(snippet)
      snippet.create_repository

      raise CreateRepositoryError, 'Repository could not be created' unless snippet.repository_exists?
    end

    # If the user provides `snippet_actions` and the repository
    # does not exist, we need to commit first the snippet info stored
    # in the database.  Mostly because the content inside `snippet_actions`
    # would assume that the file is already in the repository.
    def create_first_commit_using_db_data(snippet)
      return if snippet_actions.empty?

      attrs = commit_attrs(snippet, INITIAL_COMMIT_MSG)
      actions = [{ file_path: snippet.file_name, content: snippet.content }]

      snippet.snippet_repository.multi_files_action(current_user, actions, **attrs)
    end

    def create_commit(snippet)
      raise UpdateError unless snippet.snippet_repository

      attrs = commit_attrs(snippet, UPDATE_COMMIT_MSG)

      snippet.snippet_repository.multi_files_action(current_user, files_to_commit(snippet), **attrs)
    end

    # Because we are removing repositories we don't want to remove
    # any existing repository with data. Therefore, we cannot
    # rely on cached methods for that check in order to avoid losing
    # data.
    def repository_empty?(snippet)
      snippet.repository._uncached_exists? && !snippet.repository._uncached_has_visible_content?
    end

    def committable_attributes?
      (params.stringify_keys.keys & COMMITTABLE_ATTRIBUTES).present? || snippet_actions.any?
    end

    def build_actions_from_params(snippet)
      file_name_on_repo = snippet.file_name_on_repo

      [{ previous_path: file_name_on_repo,
         file_path: params[:file_name] || file_name_on_repo,
         content: params[:content] }]
    end
  end
end
