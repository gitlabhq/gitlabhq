# frozen_string_literal: true

module QA
  module Tools
    module Lib
      module Group
        def fetch_group_id(api_client, group_number = nil)
          group_name = if group_number
                         "gitlab-qa-sandbox-group-#{group_number}"
                       else
                         ENV['TOP_LEVEL_GROUP_NAME'] || "gitlab-qa-sandbox-group-#{Time.now.wday + 1}"
                       end

          logger.info("Fetching group #{group_name}...")

          group_search_response = get Runtime::API::Request.new(api_client, "/groups/#{group_name}").url
          group = parse_body(group_search_response)

          group[:id].nil? ? logger.warn("Top level group #{group_name} not found") : group[:id]
        end
      end
    end
  end
end
