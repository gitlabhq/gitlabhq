require 'cgi'
require 'uri'
require 'open3'

module QA
  module Git
    class Repository
      include Scenario::Actable

      def initialize
        @ssh_cmd = ""
      end

      def self.perform(*args)
        Dir.mktmpdir do |dir|
          Dir.chdir(dir) { super }
        end
      end

      def uri=(address)
        @uri = URI(address)
      end

      def username=(name)
        @username = name
        @uri.user = name
      end

      def password=(pass)
        @password = pass
        @uri.password = CGI.escape(pass).gsub('+', '%20')
      end

      def use_default_credentials
        self.username = Runtime::User.username
        self.password = Runtime::User.password
      end

      def clone(opts = '')
        run_and_redact_credentials(build_git_command("git clone #{opts} #{@uri} ./"))
      end

      def checkout(branch_name)
        `git checkout "#{branch_name}"`
      end

      def checkout_new_branch(branch_name)
        `git checkout -b "#{branch_name}"`
      end

      def shallow_clone
        clone('--depth 1')
      end

      def configure_identity(name, email)
        `git config user.name #{name}`
        `git config user.email #{email}`
      end

      def configure_ssh_command(command)
        @ssh_cmd = "GIT_SSH_COMMAND='#{command}'"
      end

      def commit_file(name, contents, message)
        add_file(name, contents)
        commit(message)
      end

      def add_file(name, contents)
        ::File.write(name, contents)

        `git add #{name}`
      end

      def commit(message)
        `git commit -m "#{message}"`
      end

      def push_changes(branch = 'master')
        output, _ = run_and_redact_credentials(build_git_command("git push #{@uri} #{branch}"))

        output
      end

      def commits
        `git log --oneline`.split("\n")
      end

      def use_ssh_key(key)
        @private_key_file = Tempfile.new("id_#{SecureRandom.hex(8)}")
        File.binwrite(@private_key_file, key.private_key)
        File.chmod(0700, @private_key_file)

        @known_hosts_file = Tempfile.new("known_hosts_#{SecureRandom.hex(8)}")
        keyscan_params = ['-H']
        keyscan_params << "-p #{@uri.port}" if @uri.port
        keyscan_params << @uri.host
        run_and_redact_credentials("ssh-keyscan #{keyscan_params.join(' ')} >> #{@known_hosts_file.path}")

        configure_ssh_command("ssh -i #{@private_key_file.path} -o UserKnownHostsFile=#{@known_hosts_file.path}")
      end

      def delete_ssh_key
        return unless @private_key_file

        @private_key_file.close(true)
        @known_hosts_file.close(true)
      end

      def build_git_command(command_str)
        [@ssh_cmd, command_str].compact.join(' ')
      end

      private

      # Since the remote URL contains the credentials, and git occasionally
      # outputs the URL. Note that stderr is redirected to stdout.
      def run_and_redact_credentials(command)
        Open3.capture2("#{command} 2>&1 | sed -E 's#://[^@]+@#://****@#g'")
      end
    end
  end
end
