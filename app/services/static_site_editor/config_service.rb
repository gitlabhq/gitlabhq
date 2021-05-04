# frozen_string_literal: true

module StaticSiteEditor
  class ConfigService < ::BaseContainerService
    ValidationError = Class.new(StandardError)

    def initialize(container:, current_user: nil, params: {})
      super

      @project = container
      @repository = project.repository
      @ref = params.fetch(:ref)
    end

    def execute
      check_access!

      file_config = load_file_config!
      file_data = file_config.to_hash_with_defaults
      generated_data = load_generated_config.data

      check_for_duplicate_keys!(generated_data, file_data)
      data = merged_data(generated_data, file_data)

      ServiceResponse.success(payload: data)
    rescue ValidationError => e
      ServiceResponse.error(message: e.message)
    rescue StandardError => e
      Gitlab::ErrorTracking.track_and_raise_exception(e)
    end

    private

    attr_reader :project, :repository, :ref

    def static_site_editor_config_file
      '.gitlab/static-site-editor.yml'
    end

    def check_access!
      unless can?(current_user, :download_code, project)
        raise ValidationError, 'Insufficient permissions to read configuration'
      end
    end

    def load_file_config!
      yaml = yaml_from_repo.presence || '{}'
      file_config = Gitlab::StaticSiteEditor::Config::FileConfig.new(yaml)

      unless file_config.valid?
        raise ValidationError, file_config.errors.first
      end

      file_config
    rescue Gitlab::StaticSiteEditor::Config::FileConfig::ConfigError => e
      raise ValidationError, e.message
    end

    def load_generated_config
      Gitlab::StaticSiteEditor::Config::GeneratedConfig.new(
        repository,
        ref,
        params.fetch(:path),
        params[:return_url]
      )
    end

    def check_for_duplicate_keys!(generated_data, file_data)
      duplicate_keys = generated_data.keys & file_data.keys
      raise ValidationError, "Duplicate key(s) '#{duplicate_keys}' found." if duplicate_keys.present?
    end

    def merged_data(generated_data, file_data)
      generated_data.merge(file_data)
    end

    def yaml_from_repo
      repository.blob_data_at(ref, static_site_editor_config_file)
    rescue GRPC::NotFound
      # Return nil in the case of a GRPC::NotFound exception, so the default config will be used.
      # Allow any other unexpected exception will be tracked and re-raised.
      nil
    end
  end
end
