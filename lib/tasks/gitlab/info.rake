# frozen_string_literal: true

namespace :gitlab do
  namespace :env do
    desc 'GitLab | Env | Show information about GitLab and its environment'
    task info: :gitlab_environment do
      # check if there is an RVM environment
      rvm_version = run_and_match(%w(rvm --version), /[\d\.]+/).try(:to_s)
      # check Ruby version
      ruby_version = run_and_match(%w(ruby --version), /[\d\.p]+/).try(:to_s)
      # check Gem version
      gem_version = run_command(%w(gem --version))
      # check Bundler version
      bunder_version = run_and_match(%w(bundle --version), /[\d\.]+/).try(:to_s)
      # check Rake version
      rake_version = run_and_match(%w(rake --version), /[\d\.]+/).try(:to_s)
      # check redis version
      redis_version = run_and_match(%w(redis-cli --version), /redis-cli (\d+\.\d+\.\d+)/).to_a

      # check for system defined proxies
      if Gitlab.ee?
        proxies = Gitlab::Proxy.detect_proxy.map {|k, v| "#{k}: #{v}"}.join("\n\t\t")
      end

      # check Git version
      git_version = run_and_match([Gitlab.config.git.bin_path, '--version'], /git version ([\d\.]+)/).to_a
      # check Go version
      go_version = run_and_match(%w(go version), /go version (.+)/).to_a

      puts ""
      puts "System information".color(:yellow)
      puts "System:\t\t#{os_name || "unknown".color(:red)}"

      if Gitlab.ee?
        puts "Proxy:\t\t#{proxies.present? ? proxies.color(:green) : "no"}"
      end

      puts "Current User:\t#{run_command(%w(whoami))}"
      puts "Using RVM:\t#{rvm_version.present? ? "yes".color(:green) : "no"}"
      puts "RVM Version:\t#{rvm_version}" if rvm_version.present?
      puts "Ruby Version:\t#{ruby_version || "unknown".color(:red)}"
      puts "Gem Version:\t#{gem_version || "unknown".color(:red)}"
      puts "Bundler Version:#{bunder_version || "unknown".color(:red)}"
      puts "Rake Version:\t#{rake_version || "unknown".color(:red)}"
      puts "Redis Version:\t#{redis_version[1] || "unknown".color(:red)}"
      puts "Git Version:\t#{git_version[1] || "unknown".color(:red)}"
      puts "Sidekiq Version:#{Sidekiq::VERSION}"
      puts "Go Version:\t#{go_version[1] || "unknown".color(:red)}"

      project = Group.new(path: "some-group").projects.build(path: "some-project")
      # construct clone URLs
      http_clone_url = project.http_url_to_repo
      ssh_clone_url  = project.ssh_url_to_repo

      if Gitlab.ee?
        geo_node_type =
          if Gitlab::Geo.current_node
            Gitlab::Geo.current_node.primary ? 'Primary' : 'Secondary'
          else
            'Undefined'.color(:red)
          end
      end

      omniauth_providers = Gitlab.config.omniauth.providers.map { |provider| provider['name'] }

      puts ""
      puts "GitLab information".color(:yellow)
      puts "Version:\t#{Gitlab::VERSION}"
      puts "Revision:\t#{Gitlab.revision}"
      puts "Directory:\t#{Rails.root}"
      puts "DB Adapter:\t#{Gitlab::Database.main.human_adapter_name}"
      puts "DB Version:\t#{Gitlab::Database.main.version}"
      puts "URL:\t\t#{Gitlab.config.gitlab.url}"
      puts "HTTP Clone URL:\t#{http_clone_url}"
      puts "SSH Clone URL:\t#{ssh_clone_url}"

      if Gitlab.ee?
        puts "Elasticsearch:\t#{Gitlab::CurrentSettings.current_application_settings.elasticsearch_indexing? ? "yes".color(:green) : "no"}"
        puts "Geo:\t\t#{Gitlab::Geo.enabled? ? "yes".color(:green) : "no"}"
        puts "Geo node:\t#{geo_node_type}" if Gitlab::Geo.enabled?
      end

      puts "Using LDAP:\t#{Gitlab.config.ldap.enabled ? "yes".color(:green) : "no"}"
      puts "Using Omniauth:\t#{Gitlab::Auth.omniauth_enabled? ? "yes".color(:green) : "no"}"
      puts "Omniauth Providers: #{omniauth_providers.join(', ')}" if Gitlab::Auth.omniauth_enabled?

      # check Gitlab Shell version
      puts ""
      puts "GitLab Shell".color(:yellow)
      puts "Version:\t#{Gitlab::Shell.version || "unknown".color(:red)}"
      puts "Repository storage paths:"
      Gitlab::GitalyClient::StorageSettings.allow_disk_access do
        Gitlab.config.repositories.storages.each do |name, repository_storage|
          puts "- #{name}: \t#{repository_storage.legacy_disk_path}"
        end
      end
      puts "GitLab Shell path:\t\t#{Gitlab.config.gitlab_shell.path}"
      puts "Git:\t\t#{Gitlab.config.git.bin_path}"
    end
  end
end
