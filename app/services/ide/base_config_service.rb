# frozen_string_literal: true

module Ide
  class BaseConfigService < ::BaseService
    ValidationError = Class.new(StandardError)

    WEBIDE_CONFIG_FILE = '.gitlab/.gitlab-webide.yml'

    attr_reader :config, :config_content

    def execute
      check_access_and_load_config!

      success
    rescue ValidationError => e
      error(e.message)
    end

    protected

    def check_access_and_load_config!
      check_access!
      load_config_content!
      load_config!
    end

    private

    def check_access!
      unless can?(current_user, :download_code, project)
        raise ValidationError, 'Insufficient permissions to read configuration'
      end
    end

    def load_config_content!
      @config_content = webide_yaml_from_repo

      unless config_content
        raise ValidationError, "Failed to load Web IDE config file '#{WEBIDE_CONFIG_FILE}' for #{params[:sha]}"
      end
    end

    def load_config!
      @config = WebIde::Config.new(config_content)

      unless @config.valid?
        raise ValidationError, @config.errors.first
      end
    rescue WebIde::Config::ConfigError => e
      raise ValidationError, e.message
    end

    def webide_yaml_from_repo
      gitlab_webide_yml_for(params[:sha])
    rescue GRPC::NotFound, GRPC::Internal
      nil
    end

    def gitlab_webide_yml_for(sha)
      project.repository.blob_data_at(sha, WEBIDE_CONFIG_FILE)
    end
  end
end
