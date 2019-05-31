# frozen_string_literal: true
module Gitlab
  module PhabricatorImport
    module Conduit
      class Maniphest
        def initialize(phabricator_url:, api_token:)
          @client = Client.new(phabricator_url, api_token)
        end

        def tasks(after: nil)
          TasksResponse.new(get_tasks(after))
        end

        private

        def get_tasks(after)
          client.get('maniphest.search',
                     params: {
                       after: after,
                       attachments: { projects: 1, subscribers: 1, columns: 1 }
                     })
        end

        attr_reader :client
      end
    end
  end
end
