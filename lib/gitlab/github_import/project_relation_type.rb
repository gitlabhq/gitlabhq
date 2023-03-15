# frozen_string_literal: true

module Gitlab
  module GithubImport
    class ProjectRelationType
      CACHE_ORGS_EXPIRES_IN = 5.minutes
      CACHE_USER_EXPIRES_IN = 1.hour

      def initialize(client)
        @client = client
      end

      def for(import_source)
        namespace = import_source.split('/')[0]
        if user?(namespace)
          'owned'
        elsif organization?(namespace)
          'organization'
        else
          'collaborated'
        end
      end

      private

      attr_reader :client

      def user?(namespace)
        github_user_login == namespace
      end

      def organization?(namespace)
        github_org_logins.include? namespace
      end

      def github_user_login
        ::Rails.cache.fetch(cache_key('user_login'), expire_in: CACHE_USER_EXPIRES_IN) do
          client.user(nil)[:login]
        end
      end

      def github_org_logins
        ::Rails.cache.fetch(cache_key('organization_logins'), expires_in: CACHE_ORGS_EXPIRES_IN) do
          logins = []
          client.each_object(:organizations) { |org| logins.push(org[:login]) }
          logins
        end
      end

      def cache_key(subject)
        ['github_import', Gitlab::CryptoHelper.sha256(client.octokit.access_token), subject].join('/')
      end
    end
  end
end
