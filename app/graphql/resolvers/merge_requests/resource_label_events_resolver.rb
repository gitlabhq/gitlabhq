# frozen_string_literal: true

module Resolvers
  module MergeRequests
    class ResourceLabelEventsResolver < BaseResolver
      type Types::MergeRequests::ResourceLabelEventType.connection_type, null: true

      argument :label_id, ::Types::GlobalIDType[::Label],
        required: false,
        prepare: ->(global_id, _ctx) { global_id&.model_id },
        description: 'Global ID of the label to filter the label events.'

      def resolve(label_id: nil)
        ::MergeRequests::ResourceLabelEventsFinder.new(object, label_id: label_id).execute
      end
    end
  end
end
