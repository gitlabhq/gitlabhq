require 'cgi'
require 'uri'
require 'open3'

module QA
  module Git
    class Repository
      include Scenario::Actable

      attr_reader :push_error

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
        self.username = Runtime::User.name
        self.password = Runtime::User.password
      end

      def clone(opts = '')
        `git clone #{opts} #{@uri.to_s} ./ #{suppress_output}`
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

      def commit_file(name, contents, message)
        add_file(name, contents)
        commit(message)
      end

      def add_file(name, contents)
        File.write(name, contents)

        `git add #{name}`
      end

      def commit(message)
        `git commit -m "#{message}"`
      end

      def push_changes(branch = 'master')
        # capture3 returns stdout, stderr and status.
        _, @push_error, _ = Open3.capture3("git push #{@uri} #{branch} #{suppress_output}")
      end

      def commits
        `git log --oneline`.split("\n")
      end

      private

      def suppress_output
        # If we're running as the default user, it's probably a temporary
        # instance and output can be useful for debugging
        return if @username == Runtime::User.default_name

        "&> #{File::NULL}"
      end
    end
  end
end
