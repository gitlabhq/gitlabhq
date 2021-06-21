# frozen_string_literal: true

module API
  module Helpers
    module SnippetsHelpers
      extend Grape::API::Helpers

      params :raw_file_params do
        requires :file_path, type: String, file_path: true, desc: 'The url encoded path to the file, e.g. lib%2Fclass%2Erb'
        requires :ref, type: String, desc: 'The name of branch, tag or commit'
      end

      params :create_file_params do
        optional :files, type: Array, desc: 'An array of files' do
          requires :file_path, type: String, file_path: true, allow_blank: false, desc: 'The path of a snippet file'
          requires :content, type: String, allow_blank: false, desc: 'The content of a snippet file'
        end

        optional :content, type: String, allow_blank: false, desc: 'The content of a snippet'

        given :content do
          requires :file_name, type: String, desc: 'The name of a snippet file'
        end

        mutually_exclusive :files, :content

        exactly_one_of :files, :content
      end

      params :update_file_params do |options|
        optional :files, type: Array, desc: 'An array of files to update' do
          requires :action, type: String,
            values: SnippetInputAction::ACTIONS.map(&:to_s),
            desc: "The type of action to perform on the file, must be one of: #{SnippetInputAction::ACTIONS.join(", ")}"
          optional :content, type: String, desc: 'The content of a snippet'
          optional :file_path, file_path: true, type: String, desc: 'The file path of a snippet file'
          optional :previous_path, file_path: true, type: String, desc: 'The previous path of a snippet file'
        end

        mutually_exclusive :files, :content
        mutually_exclusive :files, :file_name
      end

      params :minimum_update_params do
        at_least_one_of :content, :description, :files, :file_name, :title, :visibility
      end

      def content_for(snippet)
        if snippet.empty_repo?
          env['api.format'] = :txt
          content_type 'text/plain'
          header['Content-Disposition'] = 'attachment'

          snippet.content
        else
          blob = snippet.blobs.first

          send_git_blob(blob.repository, blob)
        end
      end

      def file_content_for(snippet)
        repo = snippet.repository
        commit = repo.commit(params[:ref])
        not_found!('Reference') unless commit

        blob = repo.blob_at(commit.sha, params[:file_path])
        not_found!('File') unless blob

        send_git_blob(repo, blob)
      end
    end

    def process_create_params(args)
      args[:snippet_actions] = args.delete(:files)&.map do |file|
        file[:action] = :create
        file.symbolize_keys
      end

      args
    end

    def process_update_params(args)
      args[:snippet_actions] = args.delete(:files)&.map(&:symbolize_keys)

      args
    end

    def validate_params_for_multiple_files(snippet)
      return unless params[:content] || params[:file_name]

      if snippet.multiple_files?
        render_api_error!({ error: _('To update Snippets with multiple files, you must use the `files` parameter') }, 400)
      end
    end
  end
end
