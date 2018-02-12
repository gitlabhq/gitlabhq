require 'uri'
require 'forwardable'

module QA
  module Git
    class Repository
      class Location
        extend Forwardable

        attr_reader :git_uri, :uri
        def_delegators :@uri, :user, :host, :path

        # See: config/initializers/1_settings.rb
        # Settings#build_gitlab_shell_ssh_path_prefix
        def self.parse(git_uri)
          if git_uri.start_with?('ssh://')
            new(git_uri, URI.parse(git_uri))
          else
            *rest, path = git_uri.split(':')
            # Host cannot have : so we'll need to escape it
            user_host = rest.join('%3A').sub(/\A\[(.+)\]\z/, '\1')
            new(git_uri, URI.parse("ssh://#{user_host}/#{path}"))
          end
        end

        def initialize(git_uri, uri)
          @git_uri = git_uri
          @uri = uri
        end

        def scheme
          uri.scheme || 'ssh'
        end

        def port
          uri.port || 22
        end
      end
    end
  end
end
