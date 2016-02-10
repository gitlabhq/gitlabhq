module Projects
  class UpdatePagesConfigurationService < BaseService
    attr_reader :project

    def initialize(project)
      @project = project
    end

    def execute
      update_file(pages_config_file, pages_config)
      reload_daemon
      success
    rescue => e
      error(e.message)
    end

    private

    def pages_config
      {
        domains: pages_domains_config
      }
    end

    def pages_domains_config
      project.pages_domains.map do |domain|
        {
          domain: domain.domain,
          certificate: domain.certificate,
          key: domain.key,
        }
      end
    end

    def reload_daemon
      # GitLab Pages daemon constantly watches for modification time of `pages.path`
      # It reloads configuration when `pages.path` is modified
      File.touch(Settings.pages.path)
    end

    def pages_path
      @pages_path ||= project.pages_path
    end

    def pages_config_file
      File.join(pages_path, 'config.json')
    end

    def update_file(file, data)
      if data
        File.open(file, 'w') do |file|
          file.write(data)
        end
      else
        File.rm(file, force: true)
      end
    end
  end
end
