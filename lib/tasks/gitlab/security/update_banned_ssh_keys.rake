# frozen_string_literal: true

# This a development rake task.
return if Rails.env.production?

# Update banned SSH keys from a Git repository
#
# This task:
#   - Reads banned SSH keys from a Git repository, and updates default key set at config/security/banned_ssh_keys.yml
#   - Stops uploading new keys if YAML file size is greater than 2 MB.
#   - Caution: The task adds all the files with suffix of .pub, and does NOT check the key's contents.
#
# @param git_url - Remote Git URL.
# @param output_file - Update keys to an output file. Default is config/security/banned_ssh_keys.yml.
#
# @example
#   bundle exec rake "gitlab:security:update_banned_ssh_keys[https://github.com/rapid7/ssh-badkeys]"
#
MAX_CONFIG_SIZE = 2.megabytes.freeze

namespace :gitlab do
  namespace :security do
    desc 'GitLab | Security | Update banned_ssh_keys config file from a remote Git repository'
    task :update_banned_ssh_keys, [:git_url, :output_file] => :gitlab_environment do |_t, args|
      require 'yaml'
      require 'git'
      require 'find'
      require_relative '../../../../config/environment'
      logger = Logger.new($stdout)
      begin
        exit 0 unless Rails.env.test? || Rails.env.development?
        name = args.git_url.rpartition('/').last.delete_suffix('.git')
        tmp_path = Dir.mktmpdir
        logger.info "start to clone the git repository at #{tmp_path}/#{name}"
        Git.clone(args.git_url, name, path: tmp_path)
        logger.info "Git clone finished. Next, add bad keys to config/security/banned_ssh_keys.yml."

        path = args.output_file || Rails.root.join('config/security/banned_ssh_keys.yml')
        config_size = File.size?(path) || 0
        exit 0 if config_size > MAX_CONFIG_SIZE

        config = (YAML.load_file(path) if File.exist?(path)) || {}

        Find.find("#{tmp_path}/#{name}") do |path|
          next unless path.end_with?('.pub')

          if config_size > MAX_CONFIG_SIZE
            logger.info "banned_ssh_keys.yml has grown too large - halting execution"
            break
          end

          logger.info "update bad SSH keys in #{path}"
          keys = File.readlines(path, chomp: true)
          keys.each do |key|
            pub = Gitlab::SSHPublicKey.new(key)

            type = pub.type.to_s
            config[type] = [] unless config.key?(type)

            next if config[type].include?(pub.fingerprint_sha256)

            config[type].append(pub.fingerprint_sha256)
            config_size += pub.fingerprint_sha256.size
          end
        end
      rescue StandardError => e
        logger.error "Exception: #{e.message}"
        logger.debug e.backtrace
        exit 1
      end

      logger.info "finish writing."
      File.open(path, 'w') { |file| file.write(config.to_yaml) }
    end
  end
end
