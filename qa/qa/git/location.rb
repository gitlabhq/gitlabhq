# frozen_string_literal: true

require 'uri'

module QA
  module Git
    class Location
      attr_reader :git_uri, :uri

      delegate :user, :host, :path, to: :@uri

      # See: config/initializers/1_settings.rb
      # Settings#build_gitlab_shell_ssh_path_prefix
      def initialize(git_uri)
        @git_uri = git_uri
        @uri =
          if %r{\A(?:ssh|http|https)://}.match?(git_uri)
            URI.parse(git_uri)
          else
            *rest, path = git_uri.split(':')
            # Host cannot have : so we'll need to escape it
            user_host = rest.join('%3A').sub(/\A\[(.+)\]\z/, '\1')
            URI.parse("ssh://#{user_host}/#{path}")
          end
      end

      def port
        uri.port || 22
      end
    end
  end
end
