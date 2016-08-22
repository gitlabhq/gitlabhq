module Bitbucket
  module Representation
    class Repo < Representation::Base
      attr_reader :owner, :slug

      def initialize(raw)
        super(raw)

        if full_name && full_name.split('/').size == 2
          @owner, @slug = full_name.split('/')
        end
      end

      def clone_url(token = nil)
        url = raw['links']['clone'].find { |link| link['name'] == 'https' }.fetch('href')

        if token.present?
          url.sub(/^[^\@]*/, "https://x-token-auth:#{token}")
        else
          url
        end
      end

      def description
        raw['description']
      end

      def full_name
        raw['full_name']
      end

      def has_issues?
        raw['has_issues']
      end

      def name
        raw['name']
      end

      def valid?
        raw['scm'] == 'git'
      end

      def visibility_level
        if raw['is_private']
          Gitlab::VisibilityLevel::PRIVATE
        else
          Gitlab::VisibilityLevel::PUBLIC
        end
      end

      def to_s
        full_name
      end
    end
  end
end
