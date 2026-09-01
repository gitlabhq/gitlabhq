# frozen_string_literal: true

module Mutations
  module MergeRequests
    module SavedViews
      # rubocop:disable GraphQL/GraphqlName -- Base class for the saved view mutations, it is never mounted
      class Base < ::Mutations::BaseMutation
        field :saved_view, ::Types::MergeRequests::SavedViewType,
          null: true,
          description: 'Saved view after the mutation.'

        def ready?(**args)
          raise_resource_not_available_error! unless Feature.enabled?(:mr_dashboard_saved_views, current_user)

          super
        end

        private

        def find_object(id:)
          GitlabSchema.object_from_id(id, expected_type: ::MergeRequests::SavedView)
        end

        def filter_params(filters)
          filters.to_h.compact.transform_values do |value|
            value.is_a?(Hash) ? value.compact : value
          end
        end

        def saved_view_response(result)
          raise_resource_not_available_error! if result.error? && result.reason == :forbidden

          if result.success?
            { saved_view: result.payload[:saved_view], errors: [] }
          else
            { saved_view: nil, errors: result.errors }
          end
        end
      end
      # rubocop:enable GraphQL/GraphqlName
    end
  end
end
