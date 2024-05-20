# frozen_string_literal: true

require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class Bitbucket < OmniAuth::Strategies::OAuth2
      option :name, 'bitbucket'

      option :client_options, {
        site: 'https://bitbucket.org',
        authorize_url: 'https://bitbucket.org/site/oauth2/authorize',
        token_url: 'https://bitbucket.org/site/oauth2/access_token'
      }

      uid do
        raw_info['uuid']
      end

      info do
        {
          name: raw_info['display_name'],
          username: raw_info['username'],
          avatar: raw_info['links']['avatar']['href'],
          email: primary_email
        }
      end

      def raw_info
        @raw_info ||= access_token.get('api/2.0/user').parsed
      end

      def primary_email
        primary = emails.find { |i| i['is_primary'] && i['is_confirmed'] }
        (primary && primary['email']) || nil
      end

      def emails
        email_response = access_token.get('api/2.0/user/emails').parsed
        @emails ||= (email_response && email_response['values']) || []
      end

      def callback_url
        options[:redirect_uri] || (full_host + callback_path)
      end
    end
  end
end
