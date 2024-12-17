# frozen_string_literal: true

namespace :gitlab do
  namespace :env do
    desc 'GitLab | Env | Show information about GitLab and its environment'
    task info: :gitlab_environment do
      # check if there is an RVM environment
      rvm_version = run_and_match(%w[rvm --version], /[\d\.]+/).try(:to_s)
      # check Ruby version
      ruby_version = run_and_match(%w[ruby --version], /[\d\.p]+/).try(:to_s)
      # check Gem version
      gem_version = run_command(%w[gem --version])
      # check Bundler version
      bunder_version = run_and_match(%w[bundle --version], /[\d\.]+/).try(:to_s)
      # check Rake version
      rake_version = run_and_match(%w[rake --version], /[\d\.]+/).try(:to_s)
      # check redis version
      redis_version = run_and_match(%w[redis-cli --version], /redis-cli (\d+\.\d+\.\d+)/).to_a

      # check for system defined proxies
      if Gitlab.ee?
        proxies = Gitlab::Proxy.detect_proxy.map { |k, v| "#{k}: #{v}" }.join("\n\t\t")
      end

      # check Go version
      go_version = run_and_match(%w[go version], /go version (.+)/).to_a

      puts ""
      puts Rainbow("System information").yellow
      puts "System:\t\t#{os_name || Rainbow('unknown').red}"

      if Gitlab.ee?
        puts "Proxy:\t\t#{proxies.present? ? Rainbow(proxies).green : 'no'}"
      end

      puts "Current User:\t#{run_command(%w[whoami])}"
      puts "Using RVM:\t#{rvm_version.present? ? Rainbow('yes').green : 'no'}"
      puts "RVM Version:\t#{rvm_version}" if rvm_version.present?
      puts "Ruby Version:\t#{ruby_version || Rainbow('unknown').red}"
      puts "Gem Version:\t#{gem_version || Rainbow('unknown').red}"
      puts "Bundler Version:#{bunder_version || Rainbow('unknown').red}"
      puts "Rake Version:\t#{rake_version || Rainbow('unknown').red}"
      puts "Redis Version:\t#{redis_version[1] || Rainbow('unknown').red}"
      puts "Sidekiq Version:#{Sidekiq::VERSION}"
      puts "Go Version:\t#{go_version[1] || Rainbow('unknown').red}"

      project = Group.new(path: "some-group").projects.build(path: "some-project")
      # construct clone URLs
      http_clone_url = project.http_url_to_repo
      ssh_clone_url  = project.ssh_url_to_repo

      if Gitlab.ee?
        geo_node_type =
          if Gitlab::Geo.current_node
            Gitlab::Geo.current_node.primary ? 'Primary' : 'Secondary'
          else
            Rainbow('Undefined').red
          end
      end

      omniauth_providers = Gitlab.config.omniauth.providers.map { |provider| provider['name'] }

      puts ""
      puts Rainbow("GitLab information").yellow
      puts "Version:\t#{Gitlab::VERSION}"
      puts "Revision:\t#{Gitlab.revision}"
      puts "Directory:\t#{Rails.root}"
      puts "DB Adapter:\t#{ApplicationRecord.database.human_adapter_name}"
      puts "DB Version:\t#{ApplicationRecord.database.version}"
      puts "URL:\t\t#{Gitlab.config.gitlab.url}"
      puts "HTTP Clone URL:\t#{http_clone_url}"
      puts "SSH Clone URL:\t#{ssh_clone_url}"

      if Gitlab.ee?
        puts "Elasticsearch:\t#{Gitlab::CurrentSettings.current_application_settings.elasticsearch_indexing? ? Rainbow('yes').green : 'no'}"
        puts "Geo:\t\t#{Gitlab::Geo.enabled? ? Rainbow('yes').green : 'no'}"
        puts "Geo node:\t#{geo_node_type}" if Gitlab::Geo.enabled?
      end

      puts "Using LDAP:\t#{Gitlab.config.ldap.enabled ? Rainbow('yes').green : 'no'}"
      puts "Using Omniauth:\t#{Gitlab::Auth.omniauth_enabled? ? Rainbow('yes').green : 'no'}"
      puts "Omniauth Providers: #{omniauth_providers.join(', ')}" if Gitlab::Auth.omniauth_enabled?

      # check Gitlab Shell version
      puts ""
      puts Rainbow("GitLab Shell").yellow
      puts "Version:\t#{Gitlab::Shell.version || Rainbow('unknown').red}"
      puts "Repository storages:"
      Gitlab.config.repositories.storages.each do |name, repository_storage|
        puts "- #{name}: \t#{repository_storage.gitaly_address}"
      end
      puts "GitLab Shell path:\t\t#{Gitlab.config.gitlab_shell.path}"

      # check Gitaly version
      puts ""
      puts Rainbow("Gitaly").yellow
      Gitlab.config.repositories.storages.each do |storage_name, storage|
        gitaly_server_service = Gitlab::GitalyClient::ServerService.new(storage_name)
        gitaly_server_info = gitaly_server_service.info
        puts "- #{storage_name} Address: \t#{storage.gitaly_address}"
        puts "- #{storage_name} Version: \t#{gitaly_server_info.server_version}"
        puts "- #{storage_name} Git Version: \t#{gitaly_server_info.git_version}"
      rescue GRPC::DeadlineExceeded
        puts Rainbow("Unable to reach storage #{storage_name}").red
      end
    end
  end
end
