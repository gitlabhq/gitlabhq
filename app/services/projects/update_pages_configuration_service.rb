module Projects
  class UpdatePagesConfigurationService < BaseService
    attr_reader :project

    def initialize(project)
      @project = project
    end

    def execute
      update_file(pages_cname_file, project.pages_custom_domain)
      update_file(pages_certificate_file, project.pages_custom_certificate)
      update_file(pages_certificate_file_key, project.pages_custom_certificate_key)
      reload_daemon
      success
    rescue => e
      error(e.message)
    end

    private

    def reload_daemon
      # GitLab Pages daemon constantly watches for modification time of `pages.path`
      # It reloads configuration when `pages.path` is modified
      File.touch(Settings.pages.path)
    end

    def pages_path
      @pages_path ||= project.pages_path
    end

    def pages_cname_file
      File.join(pages_path, 'CNAME')
    end

    def pages_certificate_file
      File.join(pages_path, 'domain.crt')
    end

    def pages_certificate_key_file
      File.join(pages_path, 'domain.key')
    end

    def update_file(file, data)
      if data
        File.open(file, 'w') do |file|
          file.write(data)
        end
      else
        File.rm_r(file)
      end
    end
  end
end
