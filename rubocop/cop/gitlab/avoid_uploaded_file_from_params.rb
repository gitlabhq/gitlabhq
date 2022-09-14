# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      # This cop checks for `UploadedFile.from_params` usage.
      # See https://docs.gitlab.com/ee/development/uploads/working_with_uploads.html
      #
      # @example
      #
      #   # bad
      #   class MyAwfulApi < Grape::API::Instance
      #     params do
      #       optional 'file.path', type: String
      #       optional 'file.name', type: String
      #       optional 'file.type', type: String
      #       optional 'file.size', type: Integer
      #       optional 'file.md5', type: String
      #       optional 'file.sha1', type: String
      #       optional 'file.sha256', type: String
      #     end
      #     put '/files' do
      #       uploaded_file = UploadedFile.from_params(params, :file, FileUploader.workhorse_local_upload_path)
      #     end
      #   end
      #
      #   # good
      #   class MyMuchBetterApi < Grape::API::Instance
      #     params do
      #       requires :file, type: ::API::Validations::Types::WorkhorseFile
      #     end
      #     put '/files' do
      #       uploaded_file = declared_params[:file]
      #     end
      #   end
      class AvoidUploadedFileFromParams < RuboCop::Cop::Base
        MSG = 'Use the `UploadedFile` set by `multipart.rb` instead of calling `UploadedFile.from_params` directly. See https://docs.gitlab.com/ee/development/uploads/working_with_uploads.html'

        def_node_matcher :calling_uploaded_file_from_params?, <<~PATTERN
          (send (const nil? :UploadedFile) :from_params ...)
        PATTERN

        def on_send(node)
          return unless calling_uploaded_file_from_params?(node)

          add_offense(node)
        end
      end
    end
  end
end
