# frozen_string_literal: true

module BitbucketServer
  module Representation
    class Repo < Representation::Base
      def project_key
        raw.dig('project', 'key')
      end

      def project_name
        raw.dig('project', 'name')
      end

      def slug
        raw['slug']
      end

      def browse_url
        # The JSON response contains an array of 1 element. Not sure if there
        # are cases where multiple links would be provided.
        raw.dig('links', 'self').first.fetch('href')
      end

      def clone_url
        raw['links']['clone'].find { |link| link['name'].starts_with?('http') }.fetch('href')
      end

      def description
        raw['description']
      end

      def full_name
        "#{project_name}/#{name}"
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
