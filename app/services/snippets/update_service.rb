# frozen_string_literal: true

module Snippets
  class UpdateService < Snippets::BaseService
    include SpamCheckMethods

    COMMITTABLE_ATTRIBUTES = %w(file_name content).freeze

    UpdateError = Class.new(StandardError)
    CreateRepositoryError = Class.new(StandardError)

    def execute(snippet)
      # check that user is allowed to set specified visibility_level
      new_visibility = visibility_level

      if new_visibility && new_visibility.to_i != snippet.visibility_level
        unless Gitlab::VisibilityLevel.allowed_for?(current_user, new_visibility)
          deny_visibility_level(snippet, new_visibility)

          return snippet_error_response(snippet, 403)
        end
      end

      filter_spam_check_params
      snippet.assign_attributes(params)
      spam_check(snippet, current_user)

      if save_and_commit(snippet)
        Gitlab::UsageDataCounters::SnippetCounter.count(:update)

        ServiceResponse.success(payload: { snippet: snippet } )
      else
        snippet_error_response(snippet, 400)
      end
    end

    private

    def save_and_commit(snippet)
      return false unless snippet.save

      # If the updated attributes does not need to update
      # the repository we can just return
      return true unless committable_attributes?

      create_repository_for(snippet)
      create_commit(snippet)

      true
    rescue => e
      # Restore old attributes
      unless snippet.previous_changes.empty?
        snippet.previous_changes.each { |attr, value| snippet[attr] = value[0] }
        snippet.save
      end

      snippet.errors.add(:repository, 'Error updating the snippet')
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

      snippet.snippet_repository.multi_files_action(current_user, snippet_files(snippet), commit_attrs)
    end

    def snippet_files(snippet)
      [{ previous_path: snippet.file_name_on_repo,
         file_path: params[:file_name],
         content: params[:content] }]
    end

    # Because we are removing repositories we don't want to remove
    # any existing repository with data. Therefore, we cannot
    # rely on cached methods for that check in order to avoid losing
    # data.
    def repository_empty?(snippet)
      snippet.repository._uncached_exists? && !snippet.repository._uncached_has_visible_content?
    end

    def committable_attributes?
      (params.stringify_keys.keys & COMMITTABLE_ATTRIBUTES).present?
    end
  end
end
