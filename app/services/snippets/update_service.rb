# frozen_string_literal: true

module Snippets
  class UpdateService < Snippets::BaseService
    COMMITTABLE_ATTRIBUTES = %w(file_name content).freeze

    UpdateError = Class.new(StandardError)

    def execute(snippet)
      return invalid_params_error(snippet) unless valid_params?

      if visibility_changed?(snippet) && !visibility_allowed?(snippet, visibility_level)
        return forbidden_visibility_error(snippet)
      end

      update_snippet_attributes(snippet)
      spam_check(snippet, current_user)

      if save_and_commit(snippet)
        Gitlab::UsageDataCounters::SnippetCounter.count(:update)

        ServiceResponse.success(payload: { snippet: snippet } )
      else
        snippet_error_response(snippet, 400)
      end
    end

    private

    def visibility_changed?(snippet)
      visibility_level && visibility_level.to_i != snippet.visibility_level
    end

    def update_snippet_attributes(snippet)
      # We can remove the following condition once
      # https://gitlab.com/gitlab-org/gitlab/-/issues/217801
      # is implemented.
      # Once we can perform different operations through this service
      # we won't need to keep track of the `content` and `file_name` fields
      if snippet_files.any?
        params.merge!(content: snippet_files[0].content, file_name: snippet_files[0].file_path)
      end

      snippet.assign_attributes(params)
    end

    def save_and_commit(snippet)
      return false unless snippet.save

      # If the updated attributes does not need to update
      # the repository we can just return
      return true unless committable_attributes?

      create_repository_for(snippet)
      create_commit(snippet)

      true
    rescue => e
      # Restore old attributes but re-assign changes so they're not lost
      unless snippet.previous_changes.empty?
        snippet.previous_changes.each { |attr, value| snippet[attr] = value[0] }
        snippet.save

        snippet.assign_attributes(params)
      end

      add_snippet_repository_error(snippet: snippet, error: e)

      log_error(e.message)

      # If the commit action failed we remove it because
      # we don't want to leave empty repositories
      # around, to allow cloning them.
      if repository_empty?(snippet)
        snippet.repository.remove
        snippet.snippet_repository&.delete
      end

      # Purge any existing value for repository_exists?
      snippet.repository.expire_exists_cache

      false
    end

    def create_repository_for(snippet)
      snippet.create_repository

      raise CreateRepositoryError, 'Repository could not be created' unless snippet.repository_exists?
    end

    def create_commit(snippet)
      raise UpdateError unless snippet.snippet_repository

      commit_attrs = {
        branch_name: 'master',
        message: 'Update snippet'
      }

      snippet.snippet_repository.multi_files_action(current_user, files_to_commit(snippet), commit_attrs)
    end

    # Because we are removing repositories we don't want to remove
    # any existing repository with data. Therefore, we cannot
    # rely on cached methods for that check in order to avoid losing
    # data.
    def repository_empty?(snippet)
      snippet.repository._uncached_exists? && !snippet.repository._uncached_has_visible_content?
    end

    def committable_attributes?
      (params.stringify_keys.keys & COMMITTABLE_ATTRIBUTES).present? || snippet_files.any?
    end

    def build_actions_from_params(snippet)
      file_name_on_repo = snippet.file_name_on_repo

      [{ previous_path: file_name_on_repo,
         file_path: params[:file_name] || file_name_on_repo,
         content: params[:content] }]
    end
  end
end
