# frozen_string_literal: true

module Bitbucket
  module Representation
    class Repo < Representation::Base
      def owner_and_slug
        @owner_and_slug ||= full_name.split('/', 2)
      end

      def owner
        owner_and_slug.first
      end

      def slug
        owner_and_slug.last
      end

      def clone_url(token = nil, auth_type: nil)
        url = raw['links']['clone'].find { |link| link['name'] == 'https' }.fetch('href')

        if token.present?
          clone_url = URI.parse(url)

          clone_url.user = if auth_type == :basic
                             token
                           else
                             "x-token-auth:#{token}"
                           end

          clone_url.to_s
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

      def issues_enabled?
        raw['has_issues']
      end

      def name
        raw['name']
      end

      def valid?
        raw['scm'] == 'git'
      end

      def has_wiki?
        raw['has_wiki']
      end

      def visibility_level
        if raw['is_private']
          Gitlab::VisibilityLevel::PRIVATE
        else
          Gitlab::VisibilityLevel::PUBLIC
        end
      end

      def default_branch
        raw.dig('mainbranch', 'name')
      end

      def to_s
        full_name
      end

      def error
        raw['error']
      end
    end
  end
end
