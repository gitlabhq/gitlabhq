# frozen_string_literal: true

module Wikis
  class CreateAttachmentService < Files::CreateService
    ATTACHMENT_PATH = 'uploads'
    MAX_FILENAME_LENGTH = 255

    delegate :wiki, to: :project
    delegate :repository, to: :wiki

    def initialize(*args)
      super

      @file_name = clean_file_name(params[:file_name])
      @file_path = File.join(ATTACHMENT_PATH, SecureRandom.hex, @file_name) if @file_name
      @commit_message ||= "Upload attachment #{@file_name}"
      @branch_name ||= wiki.default_branch
    end

    def create_commit!
      commit_result(create_transformed_commit(@file_content))
    end

    private

    def clean_file_name(file_name)
      return unless file_name.present?

      file_name = truncate_file_name(file_name)
      # CommonMark does not allow Urls with whitespaces, so we have to replace them
      # Using the same regex Carrierwave use to replace invalid characters
      file_name.gsub(CarrierWave::SanitizedFile.sanitize_regexp, '_')
    end

    def truncate_file_name(file_name)
      return file_name if file_name.length <= MAX_FILENAME_LENGTH

      extension = File.extname(file_name)
      truncate_at = MAX_FILENAME_LENGTH - extension.length - 1
      base_name = File.basename(file_name, extension)[0..truncate_at]
      base_name + extension
    end

    def validate!
      validate_file_name!
      validate_permissions!
    end

    def validate_file_name!
      raise_error('The file name cannot be empty') unless @file_name
    end

    def validate_permissions!
      unless can?(current_user, :create_wiki, project)
        raise_error('You are not allowed to push to the wiki')
      end
    end

    def create_transformed_commit(content)
      repository.create_file(
        current_user,
        @file_path,
        content,
        message: @commit_message,
        branch_name: @branch_name,
        author_email: @author_email,
        author_name: @author_name)
    end

    def commit_result(commit_id)
      {
        file_name: @file_name,
        file_path: @file_path,
        branch: @branch_name,
        commit: commit_id
      }
    end
  end
end
