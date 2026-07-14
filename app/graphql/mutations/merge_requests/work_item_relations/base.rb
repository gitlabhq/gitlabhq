# frozen_string_literal: true

module Mutations
  module MergeRequests
    module WorkItemRelations
      # rubocop:disable GraphQL/GraphqlName -- This is a base mutation so name is not needed here
      class Base < ::Mutations::MergeRequests::Base
        private

        def feature_enabled?(merge_request)
          Feature.enabled?(:explicit_mr_work_item_relations, merge_request.project)
        end
      end
      # rubocop:enable GraphQL/GraphqlName
    end
  end
end
