# frozen_string_literal: true
module Gitlab
  module PhabricatorImport
    module Conduit
      class User
        MAX_PAGE_SIZE = 100

        def initialize(phabricator_url:, api_token:)
          @client = Client.new(phabricator_url, api_token)
        end

        def users(phids)
          phids.each_slice(MAX_PAGE_SIZE).map { |limited_phids| get_page(limited_phids) }
        end

        private

        def get_page(phids)
          UsersResponse.new(get_users(phids))
        end

        def get_users(phids)
          client.get('user.search',
                     params: { constraints: { phids: phids } })
        end

        attr_reader :client
      end
    end
  end
end
