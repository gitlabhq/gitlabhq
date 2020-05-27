# frozen_string_literal: true

require 'cgi'
require 'uri'
require 'open3'
require 'fileutils'
require 'tmpdir'
require 'tempfile'
require 'securerandom'

module QA
  module Git
    class Repository
      include Scenario::Actable
      include Support::Repeater

      RepositoryCommandError = Class.new(StandardError)

      attr_writer :use_lfs, :gpg_key_id
      attr_accessor :env_vars

      InvalidCredentialsError = Class.new(RuntimeError)

      def initialize
        # We set HOME to the current working directory (which is a
        # temporary directory created in .perform()) so the temporarily dropped
        # .netrc can be utilised
        self.env_vars = [%Q{HOME="#{tmp_home_dir}"}]
        @use_lfs = false
        @gpg_key_id = nil
      end

      def self.perform(*args)
        Dir.mktmpdir do |dir|
          Dir.chdir(dir) { super }
        end
      end

      def password=(password)
        @password = password

        raise InvalidCredentialsError, "Please provide a username when setting a password" unless username

        try_add_credentials_to_netrc
      end

      def uri=(address)
        @uri = URI(address)
      end

      def username=(username)
        @username = username
        # Only include the user in the URI if we're using HTTP as this breaks
        # SSH authentication.
        @uri.user = username unless ssh_key_set?
      end

      def use_default_credentials
        self.username, self.password = default_credentials
      end

      def clone(opts = '')
        clone_result = run("git clone #{opts} #{uri} ./", max_attempts: 3)
        return clone_result.response unless clone_result.success?

        enable_lfs_result = enable_lfs if use_lfs?

        clone_result.to_s + enable_lfs_result.to_s
      end

      def checkout(branch_name, new_branch: false)
        opts = new_branch ? '-b' : ''
        run(%Q{git checkout #{opts} "#{branch_name}"}).to_s
      end

      def shallow_clone
        clone('--depth 1')
      end

      def configure_identity(name, email)
        run(%Q{git config user.name "#{name}"})
        run(%Q{git config user.email #{email}})
      end

      def commit_file(name, contents, message)
        add_file(name, contents)
        commit(message)
      end

      def add_file(name, contents)
        FileUtils.mkdir_p(::File.dirname(name))

        ::File.write(name, contents)

        if use_lfs?
          git_lfs_track_result = run(%Q{git lfs track #{name} --lockable})
          return git_lfs_track_result.response unless git_lfs_track_result.success?
        end

        git_add_result = run(%Q{git add #{name}})

        git_lfs_track_result.to_s + git_add_result.to_s
      end

      def delete_tag(tag_name)
        run(%Q{git push origin --delete #{tag_name}}, max_attempts: 3).to_s
      end

      def commit(message)
        run(%Q{git commit -m "#{message}"}, max_attempts: 3).to_s
      end

      def commit_with_gpg(message)
        run(%Q{git config user.signingkey #{@gpg_key_id} && git config gpg.program $(command -v gpg) && git commit -S -m "#{message}"}).to_s
      end

      def push_changes(branch = 'master')
        run("git push #{uri} #{branch}", max_attempts: 3).to_s
      end

      def merge(branch)
        run("git merge #{branch}")
      end

      def init_repository
        run("git init")
      end

      def pull(repository = nil, branch = nil)
        run(['git', 'pull', repository, branch].compact.join(' '))
      end

      def commits
        run('git log --oneline').to_s.split("\n")
      end

      def use_ssh_key(key)
        @private_key_file = Tempfile.new("id_#{SecureRandom.hex(8)}")
        File.binwrite(private_key_file, key.private_key)
        File.chmod(0700, private_key_file)

        @known_hosts_file = Tempfile.new("known_hosts_#{SecureRandom.hex(8)}")
        keyscan_params = ['-H']
        keyscan_params << "-p #{uri.port}" if uri.port
        keyscan_params << uri.host
        res = run("ssh-keyscan #{keyscan_params.join(' ')} >> #{known_hosts_file.path}")
        return res.response unless res.success?

        self.env_vars << %Q{GIT_SSH_COMMAND="ssh -i #{private_key_file.path} -o UserKnownHostsFile=#{known_hosts_file.path}"}
      end

      def delete_ssh_key
        return unless ssh_key_set?

        private_key_file.close(true)
        known_hosts_file.close(true)
      end

      def push_with_git_protocol(version, file_name, file_content, commit_message = 'Initial commit')
        self.git_protocol = version
        add_file(file_name, file_content)
        commit(commit_message)
        push_changes

        fetch_supported_git_protocol
      end

      def git_protocol=(value)
        raise ArgumentError, "Please specify the protocol you would like to use: 0, 1, or 2" unless %w[0 1 2].include?(value.to_s)

        run("git config protocol.version #{value}")
      end

      def fetch_supported_git_protocol
        # ls-remote is one command known to respond to Git protocol v2 so we use
        # it to get output including the version reported via Git tracing
        result = run("git ls-remote #{uri}", env: "GIT_TRACE_PACKET=1", max_attempts: 3)
        result.response[/git< version (\d+)/, 1] || 'unknown'
      end

      def try_add_credentials_to_netrc
        return unless add_credentials?
        return if netrc_already_contains_content?

        save_netrc_content
      end

      def file_content(file)
        run("cat #{file}").to_s
      end

      private

      attr_reader :uri, :username, :password, :known_hosts_file,
        :private_key_file, :use_lfs

      alias_method :use_lfs?, :use_lfs

      Result = Struct.new(:command, :exitstatus, :response) do
        alias_method :to_s, :response

        def success?
          exitstatus.zero?
        end
      end

      def add_credentials?
        return false if !username || !password
        return true unless ssh_key_set?

        false
      end

      def ssh_key_set?
        !private_key_file.nil?
      end

      def enable_lfs
        # git lfs install *needs* a .gitconfig defined at ${HOME}/.gitconfig
        FileUtils.mkdir_p(tmp_home_dir)
        touch_gitconfig_result = run("touch #{tmp_home_dir}/.gitconfig")
        return touch_gitconfig_result.response unless touch_gitconfig_result.success?

        git_lfs_install_result = run('git lfs install')

        touch_gitconfig_result.to_s + git_lfs_install_result.to_s
      end

      def run(command_str, env: [], max_attempts: 1)
        command = [env_vars, *env, command_str, '2>&1'].compact.join(' ')
        result = nil

        repeat_until(max_attempts: max_attempts, raise_on_failure: false) do
          Runtime::Logger.debug "Git: pwd=[#{Dir.pwd}], command=[#{command}]"
          output, status = Open3.capture2e(command)
          output.chomp!
          Runtime::Logger.debug "Git: output=[#{output}], exitstatus=[#{status.exitstatus}]"

          result = Result.new(command, status.exitstatus, output)

          result.success?
        end

        unless result.success?
          raise RepositoryCommandError, "The command #{result.command} failed (#{result.exitstatus}) with the following output:\n#{result.response}"
        end

        result
      end

      def default_credentials
        if ::QA::Runtime::User.ldap_user?
          [Runtime::User.ldap_username, Runtime::User.ldap_password]
        else
          [Runtime::User.username, Runtime::User.password]
        end
      end

      def read_netrc_content
        File.exist?(netrc_file_path) ? File.readlines(netrc_file_path) : []
      end

      def save_netrc_content
        # Despite libcurl supporting a custom .netrc location through the
        # CURLOPT_NETRC_FILE environment variable, git does not support it :(
        # Info: https://curl.haxx.se/libcurl/c/CURLOPT_NETRC_FILE.html
        #
        # This will create a .netrc in the correct working directory, which is
        # a temporary directory created in .perform()
        #
        FileUtils.mkdir_p(tmp_home_dir)
        File.open(netrc_file_path, 'a') { |file| file.puts(netrc_content) }
        File.chmod(0600, netrc_file_path)
      end

      def tmp_home_dir
        @tmp_home_dir ||= File.join(Dir.tmpdir, "qa-netrc-credentials", $$.to_s)
      end

      def netrc_file_path
        @netrc_file_path ||= File.join(tmp_home_dir, '.netrc')
      end

      def netrc_content
        "machine #{uri.host} login #{username} password #{password}"
      end

      def netrc_already_contains_content?
        read_netrc_content.grep(/^#{Regexp.escape(netrc_content)}$/).any?
      end
    end
  end
end
