# frozen_string_literal: true

module StaticSiteEditor
  class ConfigService < ::BaseContainerService
    ValidationError = Class.new(StandardError)

    def execute
      @project = container
      check_access!

      ServiceResponse.success(payload: data)
    rescue ValidationError => e
      ServiceResponse.error(message: e.message)
    end

    private

    attr_reader :project

    def check_access!
      unless can?(current_user, :download_code, project)
        raise ValidationError, 'Insufficient permissions to read configuration'
      end
    end

    def data
      check_for_duplicate_keys!
      generated_data.merge(file_data)
    end

    def generated_data
      @generated_data ||= Gitlab::StaticSiteEditor::Config::GeneratedConfig.new(
        project.repository,
        params.fetch(:ref),
        params.fetch(:path),
        params[:return_url]
      ).data
    end

    def file_data
      @file_data ||= Gitlab::StaticSiteEditor::Config::FileConfig.new.data
    end

    def check_for_duplicate_keys!
      duplicate_keys = generated_data.keys & file_data.keys
      raise ValidationError.new("Duplicate key(s) '#{duplicate_keys}' found.") if duplicate_keys.present?
    end
  end
end
