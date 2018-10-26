# frozen_string_literal: true

require 'cgi'
require 'uri'
require 'open3'
require 'fileutils'
require 'tmpdir'

module QA
  module Git
    class Repository
      include Scenario::Actable

      attr_writer :password
      attr_accessor :env_vars

      def initialize
        # We set HOME to the current working directory (which is a
        # temporary directory created in .perform()) so the temporarily dropped
        # .netrc can be utilised
        self.env_vars = [%Q{HOME="#{File.dirname(netrc_file_path)}"}]
      end

      def self.perform(*args)
        Dir.mktmpdir do |dir|
          Dir.chdir(dir) { super }
        end
      end

      def uri=(address)
        @uri = URI(address)
      end

      def username=(username)
        @username = username
        @uri.user = username
      end

      def use_default_credentials
        self.username, self.password = default_credentials

        add_credentials_to_netrc unless ssh_key_set?
      end

      def clone(opts = '')
        run("git clone #{opts} #{uri} ./")
      end

      def checkout(branch_name)
        run(%Q{git checkout "#{branch_name}"})
      end

      def checkout_new_branch(branch_name)
        run(%Q{git checkout -b "#{branch_name}"})
      end

      def shallow_clone
        clone('--depth 1')
      end

      def configure_identity(name, email)
        run(%Q{git config user.name #{name}})
        run(%Q{git config user.email #{email}})

        add_credentials_to_netrc
      end

      def commit_file(name, contents, message)
        add_file(name, contents)
        commit(message)
      end

      def add_file(name, contents)
        ::File.write(name, contents)

        run(%Q{git add #{name}})
      end

      def commit(message)
        run(%Q{git commit -m "#{message}"})
      end

      def push_changes(branch = 'master')
        run("git push #{uri} #{branch}")
      end

      def commits
        run('git log --oneline').split("\n")
      end

      def use_ssh_key(key)
        @private_key_file = Tempfile.new("id_#{SecureRandom.hex(8)}")
        File.binwrite(private_key_file, key.private_key)
        File.chmod(0700, private_key_file)

        @known_hosts_file = Tempfile.new("known_hosts_#{SecureRandom.hex(8)}")
        keyscan_params = ['-H']
        keyscan_params << "-p #{uri.port}" if uri.port
        keyscan_params << uri.host
        run("ssh-keyscan #{keyscan_params.join(' ')} >> #{known_hosts_file.path}")

        self.env_vars << %Q{GIT_SSH_COMMAND="ssh -i #{private_key_file.path} -o UserKnownHostsFile=#{known_hosts_file.path}"}
      end

      def delete_ssh_key
        return unless ssh_key_set?

        private_key_file.close(true)
        known_hosts_file.close(true)
      end

      private

      attr_reader :uri, :username, :password, :known_hosts_file, :private_key_file

      def ssh_key_set?
        !private_key_file.nil?
      end

      def run(command_str)
        command = [env_vars, command_str, '2>&1'].compact.join(' ')
        Runtime::Logger.debug "Git: command=[#{command}]"

        output, _ = Open3.capture2(command)
        output = output.chomp.gsub(/\s+$/, '')
        Runtime::Logger.debug "Git: output=[#{output}]"

        output
      end

      def default_credentials
        if ::QA::Runtime::User.ldap_user?
          [Runtime::User.ldap_username, Runtime::User.ldap_password]
        else
          [Runtime::User.username, Runtime::User.password]
        end
      end

      def tmp_netrc_directory
        @tmp_netrc_directory ||= File.join(Dir.tmpdir, "qa-netrc-credentials", $$.to_s)
      end

      def netrc_file_path
        @netrc_file_path ||= File.join(tmp_netrc_directory, '.netrc')
      end

      def netrc_content
        "machine #{uri.host} login #{username} password #{password}"
      end

      def netrc_already_contains_content?
        File.exist?(netrc_file_path) &&
          File.readlines(netrc_file_path).grep(/^#{netrc_content}$/).any?
      end

      def add_credentials_to_netrc
        # Despite libcurl supporting a custom .netrc location through the
        # CURLOPT_NETRC_FILE environment variable, git does not support it :(
        # Info: https://curl.haxx.se/libcurl/c/CURLOPT_NETRC_FILE.html
        #
        # This will create a .netrc in the correct working directory, which is
        # a temporary directory created in .perform()
        #
        return if netrc_already_contains_content?

        FileUtils.mkdir_p(tmp_netrc_directory)
        File.open(netrc_file_path, 'a') { |file| file.puts(netrc_content) }
        File.chmod(0600, netrc_file_path)
      end
    end
  end
end
