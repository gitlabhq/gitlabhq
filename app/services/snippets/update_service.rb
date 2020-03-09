# frozen_string_literal: true

module Snippets
  class UpdateService < Snippets::BaseService
    include SpamCheckMethods

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
      snippet.with_transaction_returning_status do
        snippet.save.tap do |saved|
          break false unless saved

          # In order to avoid non migrated snippets scenarios,
          # if the snippet does not have a repository we created it
          # We don't need to check if the repository exists
          # because `create_repository` already handles it
          if Feature.enabled?(:version_snippets, current_user)
            create_repository_for(snippet)
          end

          # If the snippet repository exists we commit always
          # the changes
          create_commit(snippet) if snippet.repository_exists?
        end
      rescue
        snippet.errors.add(:repository, 'Error updating the snippet')

        false
      end
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
      [{ previous_path: snippet.blobs.first&.path,
         file_path: params[:file_name],
         content: params[:content] }]
    end
  end
end
