# frozen_string_literal: true

module Projects
  class UpdatePagesConfigurationService < BaseService
    include Gitlab::Utils::StrongMemoize

    attr_reader :project

    def initialize(project)
      @project = project
    end

    def execute
      return success unless ::Settings.pages.local_store.enabled

      # If the pages were never deployed, we can't write out the config, as the
      # directory would not exist.
      # https://gitlab.com/gitlab-org/gitlab/-/issues/235139
      return success unless project.pages_deployed?

      unless file_equals?(pages_config_file, pages_config_json)
        update_file(pages_config_file, pages_config_json)
        reload_daemon
      end

      success
    end

    private

    def pages_config_json
      strong_memoize(:pages_config_json) do
        pages_config.to_json
      end
    end

    def pages_config
      {
        domains: pages_domains_config,
        https_only: project.pages_https_only?,
        id: project.project_id,
        access_control: !project.public_pages?
      }
    end

    def pages_domains_config
      enabled_pages_domains.map do |domain|
        {
          domain: domain.domain,
          certificate: domain.certificate,
          key: domain.key,
          https_only: project.pages_https_only? && domain.https?,
          id: project.project_id,
          access_control: !project.public_pages?
        }
      end
    end

    def enabled_pages_domains
      if Gitlab::CurrentSettings.pages_domain_verification_enabled?
        project.pages_domains.enabled
      else
        project.pages_domains
      end
    end

    def reload_daemon
      # GitLab Pages daemon constantly watches for modification time of `pages.path`
      # It reloads configuration when `pages.path` is modified
      update_file(pages_update_file, SecureRandom.hex(64))
    end

    def pages_path
      @pages_path ||= project.pages_path
    end

    def pages_config_file
      File.join(pages_path, 'config.json')
    end

    def pages_update_file
      File.join(::Settings.pages.path, '.update')
    end

    def update_file(file, data)
      temp_file = "#{file}.#{SecureRandom.hex(16)}"
      File.open(temp_file, 'w') do |f|
        f.write(data)
      end
      FileUtils.move(temp_file, file, force: true)
    ensure
      # In case if the updating fails
      FileUtils.remove(temp_file, force: true)
    end

    def file_equals?(file, data)
      existing_data = read_file(file)
      data == existing_data.to_s
    end

    def read_file(file)
      File.open(file, 'r') do |f|
        f.read
      end
    rescue StandardError
      nil
    end
  end
end
