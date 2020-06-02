# frozen_string_literal: true

require 'toml-rb'

module Gitlab
  module SetupHelper
    def create_configuration(dir, storage_paths, force: false)
      generate_configuration(
        configuration_toml(dir, storage_paths),
        get_config_path(dir),
        force: force
      )
    end

    # rubocop:disable Rails/Output
    def generate_configuration(toml_data, config_path, force: false)
      FileUtils.rm_f(config_path) if force

      File.open(config_path, File::WRONLY | File::CREAT | File::EXCL) do |f|
        f.puts toml_data
      end
    rescue Errno::EEXIST
      puts 'Skipping config.toml generation:'
      puts 'A configuration file already exists.'
    rescue ArgumentError => e
      puts 'Skipping config.toml generation:'
      puts e.message
    end
    # rubocop:enable Rails/Output

    module Gitaly
      extend Gitlab::SetupHelper
      class << self
        # We cannot create config.toml files for all possible Gitaly configuations.
        # For instance, if Gitaly is running on another machine then it makes no
        # sense to write a config.toml file on the current machine. This method will
        # only generate a configuration for the most common and simplest case: when
        # we have exactly one Gitaly process and we are sure it is running locally
        # because it uses a Unix socket.
        # For development and testing purposes, an extra storage is added to gitaly,
        # which is not known to Rails, but must be explicitly stubbed.
        def configuration_toml(gitaly_dir, storage_paths, gitaly_ruby: true)
          storages = []
          address = nil

          Gitlab.config.repositories.storages.each do |key, val|
            if address
              if address != val['gitaly_address']
                raise ArgumentError, "Your gitlab.yml contains more than one gitaly_address."
              end
            elsif URI(val['gitaly_address']).scheme != 'unix'
              raise ArgumentError, "Automatic config.toml generation only supports 'unix:' addresses."
            else
              address = val['gitaly_address']
            end

            storages << { name: key, path: storage_paths[key] }
          end

          config = { socket_path: address.sub(/\Aunix:/, '') }

          if Rails.env.test?
            storage_path = Rails.root.join('tmp', 'tests', 'second_storage').to_s
            storages << { name: 'test_second_storage', path: storage_path }

            config[:auth] = { token: 'secret' }
            # Compared to production, tests run in constrained environments. This
            # number is meant to grow with the number of concurrent rails requests /
            # sidekiq jobs, and concurrency will be low anyway in test.
            config[:git] = { catfile_cache_size: 5 }
          end

          config[:storage] = storages

          internal_socket_dir = File.join(gitaly_dir, 'internal_sockets')
          FileUtils.mkdir(internal_socket_dir) unless File.exist?(internal_socket_dir)
          config[:internal_socket_dir] = internal_socket_dir

          config[:'gitaly-ruby'] = { dir: File.join(gitaly_dir, 'ruby') } if gitaly_ruby
          config[:'gitlab-shell'] = { dir: Gitlab.config.gitlab_shell.path }
          config[:bin_dir] = Gitlab.config.gitaly.client_path
          config[:gitlab] = { url: Gitlab.config.gitlab.url }

          TomlRB.dump(config)
        end

        private

        def get_config_path(dir)
          File.join(dir, 'config.toml')
        end
      end
    end

    module Praefect
      extend Gitlab::SetupHelper
      class << self
        def configuration_toml(gitaly_dir, storage_paths)
          nodes = [{ storage: 'default', address: "unix:#{gitaly_dir}/gitaly.socket", primary: true, token: 'secret' }]
          storages = [{ name: 'default', node: nodes }]
          failover = { enabled: false }
          config = { socket_path: "#{gitaly_dir}/praefect.socket", memory_queue_enabled: true, virtual_storage: storages, failover: failover }
          config[:token] = 'secret' if Rails.env.test?

          TomlRB.dump(config)
        end

        private

        def get_config_path(dir)
          File.join(dir, 'praefect.config.toml')
        end
      end
    end
  end
end
