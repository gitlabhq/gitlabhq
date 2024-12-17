# frozen_string_literal: true

require 'toml-rb'

module Gitlab
  module SetupHelper
    def create_configuration(dir, storage_paths, force: false, options: {})
      generate_configuration(
        configuration_toml(dir, storage_paths, options),
        get_config_path(dir, options),
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
      puts "A configuration file for #{config_path} already exists."
    rescue ArgumentError => e
      puts 'Skipping config.toml generation:'
      puts e.message
    end
    # rubocop:enable Rails/Output

    module Workhorse
      extend Gitlab::SetupHelper
      class << self
        def configuration_toml(dir, _, _)
          config = { redis: { URL: redis_url, DB: redis_db } }

          TomlRB.dump(config)
        end

        def redis_url
          Gitlab::Redis::Workhorse.url
        end

        def redis_db
          Gitlab::Redis::Workhorse.params.fetch(:db, 0)
        end

        def get_config_path(dir, _)
          File.join(dir, 'config_path')
        end

        def compile_into(dir)
          command = %W[#{make} -C #{Rails.root.join('workhorse')} install PREFIX=#{File.absolute_path(dir)}]

          make_out, make_status = Gitlab::Popen.popen(command)
          unless make_status == 0
            warn make_out
            raise 'workhorse make failed'
          end

          # 'make install' puts the binaries in #{dir}/bin but the init script expects them in dir
          FileUtils.mv(Dir["#{dir}/bin/*"], dir)
        end

        def make
          _, which_status = Gitlab::Popen.popen(%w[which gmake])
          which_status == 0 ? 'gmake' : 'make'
        end
      end
    end

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
        def configuration_toml(gitaly_dir, storage_paths, options)
          socket_path = ensure_single_socket!
          config = { socket_path: socket_path.delete_prefix('unix:') }

          if Rails.env.test?
            # Override the set gitaly_address since Praefect is in the loop
            socket_path = File.join(gitaly_dir, options[:gitaly_socket] || "gitaly.socket")
            prometheus_listen_addr = options[:prometheus_listen_addr]

            config = {
              socket_path: socket_path.delete_prefix('unix:'),
              auth: { token: 'secret' },
              # Compared to production, tests run in constrained environments. This
              # number is meant to grow with the number of concurrent rails requests /
              # sidekiq jobs, and concurrency will be low anyway in test.
              git: {
                catfile_cache_size: 5,
                use_bundled_binaries: true
              },
              prometheus_listen_addr: prometheus_listen_addr
            }.compact
          end

          config[:storage] = storage_paths.map { |name, _| { name: name, path: storage_paths[name].to_s } }

          runtime_dir = options[:runtime_dir] || File.join(gitaly_dir, 'run')
          FileUtils.mkdir_p(runtime_dir)
          config[:runtime_dir] = runtime_dir

          config[:'gitlab-shell'] = { dir: Gitlab.config.gitlab_shell.path }
          config[:bin_dir] = File.expand_path(File.join(gitaly_dir, '_build', 'bin')) # binaries by default are in `_build/bin`
          config[:gitlab] = { url: Gitlab.config.gitlab.url }
          config[:logging] = { dir: Rails.root.join('log').to_s }
          config[:transactions] = { enabled: true } if options[:transactions_enabled]

          TomlRB.dump(config)
        end

        # We cannot create config.toml files for all possible Gitaly
        # configurations. For instance, if Gitaly is running on another machine
        # then it makes no sense to write a config.toml file on the current
        # machine. This method validates that we have the most common and
        # simplest case: when we have exactly one Gitaly process and we are
        # sure it is running locally because it uses a Unix socket.
        def ensure_single_socket!
          addresses = Gitlab.config.repositories.storages.map { |_, storage| storage[:gitaly_address] }.uniq

          raise ArgumentError, "Your gitlab.yml contains more than one gitaly_address." if addresses.length > 1

          address = addresses.first

          if URI(address).scheme != 'unix'
            raise ArgumentError, "Automatic config.toml generation only supports 'unix:' addresses."
          end

          address
        end

        private

        def get_config_path(dir, options)
          config_filename = options[:config_filename] || 'config.toml'
          File.join(dir, config_filename)
        end
      end
    end

    module Praefect
      extend Gitlab::SetupHelper
      class << self
        def configuration_toml(gitaly_dir, _storage_paths, options)
          raise 'This configuration is only intended for test' unless Rails.env.test?

          nodes = [{ storage: 'default', address: "unix:#{gitaly_dir}/gitaly.socket", primary: true, token: 'secret' }]
          second_storage_nodes = [{ storage: 'test_second_storage', address: "unix:#{gitaly_dir}/gitaly2.socket", primary: true, token: 'secret' }]

          storages = [{ name: 'default', node: nodes }, { name: 'test_second_storage', node: second_storage_nodes }]

          config = {
            socket_path: "#{gitaly_dir}/praefect.socket",
            virtual_storage: storages,
            token: 'secret'
          }

          if options[:per_repository]
            failover = { enabled: true, election_strategy: 'per_repository' }
            database = { host: options.fetch(:pghost),
                         port: options.fetch(:pgport).to_i,
                         user: options.fetch(:pguser),
                         dbname: options.fetch(:dbname, 'praefect_test') }

            config.merge!(database: database,
              failover: failover)
          else
            failover = { enabled: false, election_strategy: 'local' }

            config.merge!(
              i_understand_my_election_strategy_is_unsupported_and_will_be_removed_without_warning: true,
              memory_queue_enabled: true,
              failover: failover
            )
          end

          TomlRB.dump(config)
        end

        private

        def get_config_path(dir, options)
          config_filename = options[:config_filename] || 'praefect.config.toml'
          File.join(dir, config_filename)
        end
      end
    end
  end
end
