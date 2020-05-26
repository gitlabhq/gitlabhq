# frozen_string_literal: true

module Snippets
  class CreateService < Snippets::BaseService
    def execute
      @snippet = build_from_params

      return invalid_params_error(@snippet) unless valid_params?

      unless visibility_allowed?(@snippet, @snippet.visibility_level)
        return forbidden_visibility_error(@snippet)
      end

      @snippet.author = current_user

      spam_check(@snippet, current_user)

      if save_and_commit
        UserAgentDetailService.new(@snippet, @request).create
        Gitlab::UsageDataCounters::SnippetCounter.count(:create)

        move_temporary_files

        ServiceResponse.success(payload: { snippet: @snippet } )
      else
        snippet_error_response(@snippet, 400)
      end
    end

    private

    def build_from_params
      if project
        project.snippets.build(create_params)
      else
        PersonalSnippet.new(create_params)
      end
    end

    # If the snippet_files param is present
    # we need to fill content and file_name from
    # the model
    def create_params
      return params if snippet_files.empty?

      params.merge(content: snippet_files[0].content, file_name: snippet_files[0].file_path)
    end

    def save_and_commit
      snippet_saved = @snippet.save

      if snippet_saved
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

      add_snippet_repository_error(snippet: @snippet, error: e)

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

      @snippet.snippet_repository.multi_files_action(current_user, files_to_commit(@snippet), commit_attrs)
    end

    def move_temporary_files
      return unless @snippet.is_a?(PersonalSnippet)

      uploaded_assets.each do |file|
        FileMover.new(file, from_model: current_user, to_model: @snippet).execute
      end
    end

    def build_actions_from_params(_snippet)
      [{ file_path: params[:file_name], content: params[:content] }]
    end
  end
end
