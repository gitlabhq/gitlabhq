require 'uri'

module QA
  module Git
    class Repository
      include Scenario::Actable

      def self.perform(*args)
        Dir.mktmpdir do |dir|
          Dir.chdir(dir) { super }
        end
      end

      def location=(address)
        @location = address
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
        `git clone #{opts} #{@uri.to_s} ./`
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
        `git push #{@uri.to_s} #{branch}`
      end

      def commits
        `git log --oneline`.split("\n")
      end
    end
  end
end
