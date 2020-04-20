# frozen_string_literal: true

module Snippets
  class CreateService < Snippets::BaseService
    include SpamCheckMethods

    CreateRepositoryError = Class.new(StandardError)

    def execute
      filter_spam_check_params

      @snippet = if project
                   project.snippets.build(params)
                 else
                   PersonalSnippet.new(params)
                 end

      unless Gitlab::VisibilityLevel.allowed_for?(current_user, @snippet.visibility_level)
        deny_visibility_level(@snippet)

        return snippet_error_response(@snippet, 403)
      end

      @snippet.author = current_user

      spam_check(@snippet, current_user)

      if save_and_commit
        UserAgentDetailService.new(@snippet, @request).create
        Gitlab::UsageDataCounters::SnippetCounter.count(:create)

        ServiceResponse.success(payload: { snippet: @snippet } )
      else
        snippet_error_response(@snippet, 400)
      end
    end

    private

    def save_and_commit
      snippet_saved = @snippet.save

      if snippet_saved && Feature.enabled?(:version_snippets, current_user)
        create_repository
        create_commit
      end

      snippet_saved
    rescue => e # Rescuing all because we can receive Creation exceptions, GRPC exceptions, Git exceptions, ...
      log_error(e.message)

      # If the commit action failed we need to remove the repository if exists
      @snippet.repository.remove if @snippet.repository_exists?

      # If the snippet was created, we need to remove it as we
      # would do like if it had had any validation error
      # and reassign a dupe so we don't return the deleted snippet
      if @snippet.persisted?
        @snippet.delete
        @snippet = @snippet.dup
      end

      @snippet.errors.add(:base, e.message)

      false
    end

    def create_repository
      @snippet.create_repository

      raise CreateRepositoryError, 'Repository could not be created' unless @snippet.repository_exists?
    end

    def create_commit
      commit_attrs = {
        branch_name: 'master',
        message: 'Initial commit'
      }

      @snippet.snippet_repository.multi_files_action(current_user, snippet_files, commit_attrs)
    end

    def snippet_files
      [{ file_path: params[:file_name], content: params[:content] }]
    end
  end
end
