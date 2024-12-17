# frozen_string_literal: true

require 'cgi'
require 'uri'
require 'fileutils'
require 'tmpdir'

module QA
  module Git
    class Repository
      include Scenario::Actable
      include Support::Repeater
      include Support::Run

      attr_writer :use_lfs, :gpg_key_id
      attr_accessor :env_vars, :default_branch

      InvalidCredentialsError = Class.new(RuntimeError)

      def initialize(command_retry_sleep_interval: 10)
        # We set HOME to the current working directory (which is a
        # temporary directory created in .perform()) so the temporarily dropped
        # .netrc can be utilised
        self.env_vars = [%(HOME="#{tmp_home_dir}")]
        @use_lfs = false
        @gpg_key_id = nil
        @default_branch = Runtime::Env.default_branch
        @command_retry_sleep_interval = command_retry_sleep_interval
      end

      attr_reader :command_retry_sleep_interval

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

      def use_default_identity
        configure_identity(default_user.name, default_user.email)
      end

      def clone(opts = '')
        clone_result = run_git("git clone #{opts} #{uri} ./", max_attempts: 3)
        return clone_result.response unless clone_result.success?

        enable_lfs_result = enable_lfs if use_lfs?

        clone_result.to_s + enable_lfs_result.to_s
      end

      def checkout(branch_name, new_branch: false)
        opts = new_branch ? '-b' : ''
        run_git(%(git checkout #{opts} "#{branch_name}")).to_s
      end

      def shallow_clone
        clone('--depth 1')
      end

      def configure_identity(name, email)
        run_git(%(git config user.name "#{name}"))
        run_git(%(git config user.email #{email}))
      end

      def commit_file(name, contents, message)
        add_file(name, contents)
        commit(message)
      end

      def add_file(name, contents)
        FileUtils.mkdir_p(::File.dirname(name))

        ::File.write(name, contents)

        if use_lfs?
          git_lfs_track_result = run_git(%(git lfs track "#{name}" --lockable))
          return git_lfs_track_result.response unless git_lfs_track_result.success?
        end

        git_add_result = run_git(%(git add "#{name}"))

        git_lfs_track_result.to_s + git_add_result.to_s
      end

      def add_tag(tag_name)
        run_git("git tag #{tag_name}").to_s
      end

      def delete_tag(tag_name, max_attempts: 3)
        run_git(%(git push origin --delete #{tag_name}), max_attempts: max_attempts).to_s
      end

      def commit(message)
        run_git(%(git commit -m "#{message}"), max_attempts: 3).to_s
      end

      def commit_with_gpg(message)
        run_git(%{git config user.signingkey #{@gpg_key_id} && git config gpg.program $(command -v gpg) && git commit -S -m "#{message}"}).to_s
      end

      def current_branch
        run_git("git rev-parse --abbrev-ref HEAD").to_s
      end

      def push_changes(branch = @default_branch, push_options: nil, max_attempts: 3, raise_on_failure: true)
        cmd = ['git push']
        cmd << push_options_hash_to_string(push_options)
        cmd << uri
        cmd << branch
        run_git(cmd.compact.join(' '), raise_on_failure: raise_on_failure, max_attempts: max_attempts).to_s
      end

      def push_all_branches
        run_git("git push --all").to_s
      end

      def push_tags_and_branches(branches)
        run_git("git push --tags origin #{branches.join(' ')}").to_s
      end

      def merge(branch)
        run_git("git merge #{branch}")
      end

      def init_repository
        cmd = "git init --initial-branch=#{default_branch}"
        cmd += " --object-format=sha256" if Runtime::Env.use_sha256_repository_object_storage
        run_git(cmd)
      end

      def pull(repository = nil, branch = nil)
        run_git(['git', 'pull', repository, branch].compact.join(' '))
      end

      def commits
        run_git('git log --oneline').to_s.split("\n")
      end

      def use_ssh_key(key)
        @ssh = Support::SSH.perform do |ssh|
          ssh.key = key
          ssh.uri = uri
          ssh.setup(env: env_vars)
          ssh
        end

        env_vars << %(GIT_SSH_COMMAND="ssh -i #{ssh.private_key_file.path} -o UserKnownHostsFile=#{ssh.known_hosts_file.path} -o IdentitiesOnly=yes")
      end

      def delete_ssh_key
        return unless ssh_key_set?

        ssh.delete
      end

      def push_with_git_protocol(version, file_name, file_content, commit_message = 'Initial commit')
        self.git_protocol = version
        add_file(file_name, file_content)
        commit(commit_message)
        push_changes

        fetch_supported_git_protocol
      end

      def git_protocol=(value)
        unless %w[0 1 2].include?(value.to_s)
          raise ArgumentError, "Please specify the protocol you would like to use: 0, 1, or 2"
        end

        run_git("git config protocol.version #{value}")
      end

      def fetch_supported_git_protocol
        # ls-remote is one command known to respond to Git protocol v2 so we use
        # it to get output including the version reported via Git tracing
        result = run_git("git ls-remote #{uri}", max_attempts: 3, env: [*env_vars, "GIT_TRACE_PACKET=1"])
        result.response[/ls-remote< version (\d+)/, 1] || 'unknown'
      end

      def try_add_credentials_to_netrc
        return unless add_credentials?
        return if netrc_already_contains_content?

        save_netrc_content
      end

      def file_content(file)
        run("cat #{file}").to_s
      end

      def delete_netrc
        FileUtils.rm_f(netrc_file_path)
      end

      def remote_branches
        # This gets the remote branch names
        # When executed on a fresh repo it returns the default branch name

        run_git('git --no-pager branch --list --remotes --format="%(refname:lstrip=3)"').to_s.split("\n")
      end

      # Gets the size of the repository using `git rev-list --all --objects --use-bitmap-index --disk-usage` as
      # Gitaly does (see https://gitlab.com/gitlab-org/gitlab/-/issues/357680)
      def local_size
        internal_refs = %w[
          refs/keep-around/
          refs/merge-requests/
          refs/pipelines/
          refs/remotes/
          refs/tmp/
          refs/environments/
        ]
        cmd = <<~CMD
          git rev-list #{internal_refs.map { |r| "--exclude='#{r}*'" }.join(' ')} \
          --not --alternate-refs --not \
          --all --objects --use-bitmap-index --disk-usage
        CMD

        run_git(cmd).to_i
      end

      # Performs garbage collection
      def run_gc
        run_git('git gc')
      end

      private

      attr_reader :uri, :username, :password, :ssh, :use_lfs

      alias_method :use_lfs?, :use_lfs

      def default_user
        @default_user ||= Runtime::User::Store.test_user || Runtime::User::Store.admin_user
      end

      def add_credentials?
        return false if !username || !password
        return true unless ssh_key_set?

        false
      end

      def ssh_key_set?
        ssh && !ssh.private_key_file.nil?
      end

      def enable_lfs
        # git lfs install *needs* a .gitconfig defined at ${HOME}/.gitconfig
        FileUtils.mkdir_p(tmp_home_dir)
        touch_gitconfig_result = run("touch #{tmp_home_dir}/.gitconfig")
        return touch_gitconfig_result.response unless touch_gitconfig_result.success?

        git_lfs_install_result = run_git('git lfs install')

        touch_gitconfig_result.to_s + git_lfs_install_result.to_s
      end

      def default_credentials
        [default_user.username, default_user.password]
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
        File.chmod(0o600, netrc_file_path)
      end

      def tmp_home_dir
        @tmp_home_dir ||= File.join(Dir.tmpdir, "qa-netrc-credentials", $$.to_s)
      end

      def push_options_hash_to_string(opts)
        return if opts.nil?

        prefix = "-o merge_request"
        opts.each_with_object([]) do |(key, value), options|
          case value
          when Array
            value.each do |item|
              options << "#{prefix}.#{key}=\"#{item}\""
            end
          when true
            options << "#{prefix}.#{key}"
          else
            options << "#{prefix}.#{key}=\"#{value}\""
          end
        end.join(' ')
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

      def run_git(command_str, raise_on_failure: true, env: env_vars, max_attempts: 1)
        run(
          command_str,
          raise_on_failure: raise_on_failure,
          env: env,
          max_attempts: max_attempts,
          sleep_internal: command_retry_sleep_interval,
          log_prefix: 'Git: '
        )
      end
    end
  end
end
