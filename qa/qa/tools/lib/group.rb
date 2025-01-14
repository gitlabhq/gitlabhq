# frozen_string_literal: true

module QA
  module Tools
    module Lib
      module Group
        include Support::API
        def fetch_group_id(api_client, name = ENV['TOP_LEVEL_GROUP_NAME'])
          group_name = name || "gitlab-qa-sandbox-group-#{Time.now.wday + 1}"

          logger.info("Fetching group #{group_name}...")

          group_search_response = get Runtime::API::Request.new(api_client, "/groups/#{group_name}").url

          if group_search_response.code != HTTP_STATUS_OK
            logger.error("Response code #{group_search_response.code}: #{group_search_response.body}")
            exit 1 if group_search_response.code == HTTP_STATUS_UNAUTHORIZED
            return
          end

          group = parse_body(group_search_response)

          logger.warn("Top level group #{group_name} not found") if group[:id].nil?

          group[:id]
        end
      end
    end
  end
end
