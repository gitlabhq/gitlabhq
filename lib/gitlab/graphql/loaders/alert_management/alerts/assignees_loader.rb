# frozen_string_literal: true

module Gitlab
  module Graphql
    module Loaders
      module AlertManagement
        module Alerts
          # Batches requests for AlertManagement::Alert#assignees
          # to avoid N+1 queries
          class AssigneesLoader
            # @param alert_id [Integer]
            # @param authorization_filter [Proc] Filter to be applied
            #                             to output assignees
            def initialize(alert_id, authorization_filter)
              @alert_id = alert_id
              @authorization_filter = authorization_filter
            end

            # Returns BatchLoader::GraphQL which evaluates
            # to a Gitlab::Graphql::FilterableArray of User objects
            def find
              BatchLoader::GraphQL.for(alert_id).batch(default_value: default_value) do |alert_ids, loader|
                load_assignees(loader, alert_ids)
              end
            end

            private

            attr_reader :alert_id, :authorization_filter

            def default_value
              Gitlab::Graphql::FilterableArray.new(authorization_filter)
            end

            def load_assignees(loader, alert_ids)
              ::AlertManagement::AlertAssignee
                .for_alert_ids(alert_ids)
                .each { |alert_assignee| add_assignee_for_alert(loader, alert_assignee) }
            end

            def add_assignee_for_alert(loader, alert_assignee)
              # loader optionally accepts a block, allowing
              # access to the current expected output, allowing
              # us to collect assignees
              loader.call(alert_assignee.alert_id) { |assignees| assignees << alert_assignee.assignee }
            end
          end
        end
      end
    end
  end
end
