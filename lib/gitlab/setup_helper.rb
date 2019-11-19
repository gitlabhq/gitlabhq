# frozen_string_literal: true

require 'toml-rb'

module Gitlab
  module SetupHelper
    class << self
      # We cannot create config.toml files for all possible Gitaly configuations.
      # For instance, if Gitaly is running on another machine then it makes no
      # sense to write a config.toml file on the current machine. This method will
      # only generate a configuration for the most common and simplest case: when
      # we have exactly one Gitaly process and we are sure it is running locally
      # because it uses a Unix socket.
      # For development and testing purposes, an extra storage is added to gitaly,
      # which is not known to Rails, but must be explicitly stubbed.
      def gitaly_configuration_toml(gitaly_dir, storage_paths, gitaly_ruby: true)
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

        if Rails.env.test?
          storage_path = Rails.root.join('tmp', 'tests', 'second_storage').to_s

          FileUtils.mkdir(storage_path) unless File.exist?(storage_path)
          storages << { name: 'test_second_storage', path: storage_path }
        end

        config = { socket_path: address.sub(/\Aunix:/, ''), storage: storages }
        config[:auth] = { token: 'secret' } if Rails.env.test?

        internal_socket_dir = File.join(gitaly_dir, 'internal_sockets')
        FileUtils.mkdir(internal_socket_dir) unless File.exist?(internal_socket_dir)
        config[:internal_socket_dir] = internal_socket_dir

        config[:'gitaly-ruby'] = { dir: File.join(gitaly_dir, 'ruby') } if gitaly_ruby
        config[:'gitlab-shell'] = { dir: Gitlab.config.gitlab_shell.path }
        config[:bin_dir] = Gitlab.config.gitaly.client_path

        if Rails.env.test?
          # Compared to production, tests run in constrained environments. This
          # number is meant to grow with the number of concurrent rails requests /
          # sidekiq jobs, and concurrency will be low anyway in test.
          config[:git] = { catfile_cache_size: 5 }
        end

        TomlRB.dump(config)
      end

      # rubocop:disable Rails/Output
      def create_gitaly_configuration(dir, storage_paths, force: false)
        config_path = File.join(dir, 'config.toml')
        FileUtils.rm_f(config_path) if force

        File.open(config_path, File::WRONLY | File::CREAT | File::EXCL) do |f|
          f.puts gitaly_configuration_toml(dir, storage_paths)
        end
      rescue Errno::EEXIST
        puts "Skipping config.toml generation:"
        puts "A configuration file already exists."
      rescue ArgumentError => e
        puts "Skipping config.toml generation:"
        puts e.message
      end
      # rubocop:enable Rails/Output
    end
  end
end
