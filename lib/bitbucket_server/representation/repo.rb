module BitbucketServer
  module Representation
    class Repo < Representation::Base
      attr_reader :owner, :slug

      def initialize(raw)
        super(raw)
      end

      def owner
        project['name']
      end

      def slug
        raw['slug']
      end

      def clone_url(token = nil)
        url = raw['links']['clone'].find { |link| link['name'].starts_with?('http') }.fetch('href')

        if token.present?
          clone_url = URI.parse(url)
          clone_url.user = "x-token-auth:#{token}"
          clone_url.to_s
        else
          url
        end
      end

      def description
        project['description']
      end

      def full_name
        "#{owner}/#{name}"
      end

      def issues_enabled?
        true
      end

      def name
        raw['name']
      end

      def valid?
        raw['scmId'] == 'git'
      end

      def has_wiki?
        false
      end

      def visibility_level
        if project['public']
          Gitlab::VisibilityLevel::PUBLIC
        else
          Gitlab::VisibilityLevel::PRIVATE
        end
      end

      def project
        raw['project']
      end

      def to_s
        full_name
      end
    end
  end
end
