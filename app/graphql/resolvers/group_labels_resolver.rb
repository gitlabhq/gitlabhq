# frozen_string_literal: true

module Resolvers
  class GroupLabelsResolver < LabelsResolver
    type Types::LabelType.connection_type, null: true

    argument :include_descendant_groups, GraphQL::Types::Boolean,
             required: false,
             description: 'Include labels from descendant groups.',
             default_value: false

    argument :only_group_labels, GraphQL::Types::Boolean,
             required: false,
             description: 'Include only group level labels.',
             default_value: false
  end
end
