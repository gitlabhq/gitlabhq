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
      def gitaly_configuration_toml(gitaly_dir, gitaly_ruby: true)
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

          storages << { name: key, path: val['path'] }
        end

        if Rails.env.test?
          storages << { name: 'test_second_storage', path: Rails.root.join('tmp', 'tests', 'second_storage').to_s }
        end

        config = { socket_path: address.sub(/\Aunix:/, ''), storage: storages }
        config[:auth] = { token: 'secret' } if Rails.env.test?
        config[:'gitaly-ruby'] = { dir: File.join(gitaly_dir, 'ruby') } if gitaly_ruby
        config[:'gitlab-shell'] = { dir: Gitlab.config.gitlab_shell.path }
        config[:bin_dir] = Gitlab.config.gitaly.client_path

        TomlRB.dump(config)
      end

      # rubocop:disable Rails/Output
      def create_gitaly_configuration(dir, force: false)
        config_path = File.join(dir, 'config.toml')
        FileUtils.rm_f(config_path) if force

        File.open(config_path, File::WRONLY | File::CREAT | File::EXCL) do |f|
          f.puts gitaly_configuration_toml(dir)
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
