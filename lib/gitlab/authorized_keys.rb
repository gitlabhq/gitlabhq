# frozen_string_literal: true

module Gitlab
  class AuthorizedKeys
    KeyError = Class.new(StandardError)

    attr_reader :logger

    # Initializes the class
    #
    # @param [Gitlab::Logger] logger
    def initialize(logger = Gitlab::AppLogger)
      @logger = logger
    end

    # Checks if the file is accessible or not
    #
    # @return [Boolean]
    def accessible?
      open_authorized_keys_file('r') { true }
    rescue Errno::ENOENT, Errno::EACCES
      false
    end

    # Creates the authorized_keys file if it doesn't exist
    #
    # @return [Boolean]
    def create
      open_authorized_keys_file(File::CREAT) { true }
    rescue Errno::EACCES
      false
    end

    # Add id and its key to the authorized_keys file
    #
    # @param [String] id identifier of key prefixed by `key-`
    # @param [String] key public key to be added
    # @return [Boolean]
    def add_key(id, key)
      lock do
        public_key = strip(key)
        logger.info("Adding key (#{id}): #{public_key}")
        open_authorized_keys_file('a') { |file| file.puts(key_line(id, public_key)) }
      end

      true
    end

    # Atomically add all the keys to the authorized_keys file
    #
    # @param [Array<::Key>] keys list of Key objects to be added
    # @return [Boolean]
    def batch_add_keys(keys)
      lock(300) do # Allow 300 seconds (5 minutes) for batch_add_keys
        open_authorized_keys_file('a') do |file|
          keys.each do |key|
            public_key = strip(key.key)
            logger.info("Adding key (#{key.shell_id}): #{public_key}")
            file.puts(key_line(key.shell_id, public_key))
          end
        end
      end

      true
    rescue Gitlab::AuthorizedKeys::KeyError
      false
    end

    # Remove key by ID from the authorized_keys file
    #
    # @param [String] id identifier of the key to be removed prefixed by `key-`
    # @return [Boolean]
    def remove_key(id)
      lock do
        logger.info("Removing key (#{id})")
        open_authorized_keys_file('r+') do |f|
          while line = f.gets
            next unless line.start_with?("command=\"#{command(id)}\"")

            f.seek(-line.length, IO::SEEK_CUR)
            # Overwrite the line with #'s. Because the 'line' variable contains
            # a terminating '\n', we write line.length - 1 '#' characters.
            f.write('#' * (line.length - 1))
          end
        end
      end

      true
    rescue Errno::ENOENT
      false
    end

    # Clear the authorized_keys file
    #
    # @return [Boolean]
    def clear
      open_authorized_keys_file('w') { |file| file.puts '# Managed by gitlab-rails' }

      true
    end

    # Read the authorized_keys file and return IDs of each key
    #
    # @return [Array<Integer>]
    def list_key_ids
      logger.info('Listing all key IDs')

      [].tap do |a|
        open_authorized_keys_file('r') do |f|
          f.each_line do |line|
            key_id = line.match(/key-(\d+)/)

            next unless key_id

            a << key_id[1].chomp.to_i
          end
        end
      end
    rescue Errno::ENOENT
      []
    end

    def file
      @file ||= Gitlab.config.gitlab_shell.authorized_keys_file
    end

    private

    def lock(timeout = 10)
      File.open("#{file}.lock", "w+") do |f|
        f.flock File::LOCK_EX
        Timeout.timeout(timeout) { yield }
      ensure
        f.flock File::LOCK_UN
      end
    end

    def open_authorized_keys_file(mode)
      File.open(file, mode, 0o600) do |file|
        file.chmod(0o600)
        yield file
      end
    end

    def key_line(id, key)
      key = key.chomp

      if key.include?("\n") || key.include?("\t")
        raise KeyError, "Invalid public_key: #{key.inspect}"
      end

      %(command="#{command(id)}",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty #{strip(key)})
    end

    def command(id)
      unless /\A[a-z0-9-]+\z/.match?(id)
        raise KeyError, "Invalid ID: #{id.inspect}"
      end

      "#{File.join(Gitlab.config.gitlab_shell.path, 'bin', 'gitlab-shell')} #{id}"
    end

    def strip(key)
      key.split(/ +/)[0, 2].join(' ')
    end
  end
end
