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
      puts 'A configuration file already exists.'
    rescue ArgumentError => e
      puts 'Skipping config.toml generation:'
      puts e.message
    end
    # rubocop:enable Rails/Output

    module Workhorse
      extend Gitlab::SetupHelper
      class << self
        def configuration_toml(dir, _, _)
          config = { redis: { URL: redis_url } }

          TomlRB.dump(config)
        end

        def redis_url
          Gitlab::Redis::SharedState.url
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
        def configuration_toml(gitaly_dir, storage_paths, options, gitaly_ruby: true)
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
            socket_filename = options[:gitaly_socket] || "gitaly.socket"
            prometheus_listen_addr = options[:prometheus_listen_addr]

            git_bin_path = File.expand_path('../gitaly/_build/deps/git/install/bin/git')
            git_bin_path = nil unless File.exist?(git_bin_path)

            config = {
              # Override the set gitaly_address since Praefect is in the loop
              socket_path: File.join(gitaly_dir, socket_filename),
              auth: { token: 'secret' },
              # Compared to production, tests run in constrained environments. This
              # number is meant to grow with the number of concurrent rails requests /
              # sidekiq jobs, and concurrency will be low anyway in test.
              git: {
                catfile_cache_size: 5,
                bin_path: git_bin_path
              }.compact,
              prometheus_listen_addr: prometheus_listen_addr
            }.compact

            storage_path = Rails.root.join('tmp', 'tests', 'second_storage').to_s
            storages << { name: 'test_second_storage', path: storage_path }
          end

          config[:storage] = storages

          internal_socket_dir = options[:internal_socket_dir] || File.join(gitaly_dir, 'internal_sockets')
          FileUtils.mkdir(internal_socket_dir) unless File.exist?(internal_socket_dir)
          config[:internal_socket_dir] = internal_socket_dir

          config[:'gitaly-ruby'] = { dir: File.join(gitaly_dir, 'ruby') } if gitaly_ruby
          config[:'gitlab-shell'] = { dir: Gitlab.config.gitlab_shell.path }
          config[:bin_dir] = File.join(gitaly_dir, '_build', 'bin') # binaries by default are in `_build/bin`
          config[:gitlab] = { url: Gitlab.config.gitlab.url }
          config[:logging] = { dir: Rails.root.join('log').to_s }

          TomlRB.dump(config)
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
        def configuration_toml(gitaly_dir, _, _)
          nodes = [{ storage: 'default', address: "unix:#{gitaly_dir}/gitaly.socket", primary: true, token: 'secret' }]
          second_storage_nodes = [{ storage: 'test_second_storage', address: "unix:#{gitaly_dir}/gitaly2.socket", primary: true, token: 'secret' }]

          storages = [{ name: 'default', node: nodes }, { name: 'test_second_storage', node: second_storage_nodes }]
          failover = { enabled: false, election_strategy: 'local' }
          config = {
            i_understand_my_election_strategy_is_unsupported_and_will_be_removed_without_warning: true,
            socket_path: "#{gitaly_dir}/praefect.socket",
            memory_queue_enabled: true,
            virtual_storage: storages,
            failover: failover
          }
          config[:token] = 'secret' if Rails.env.test?

          TomlRB.dump(config)
        end

        private

        def get_config_path(dir, _)
          File.join(dir, 'praefect.config.toml')
        end
      end
    end
  end
end
