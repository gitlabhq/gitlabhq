# frozen_string_literal: true

module Types
  module WorkItems
    class RelatedLinkTypeEnum < BaseEnum
      graphql_name 'WorkItemRelatedLinkType'
      description 'Values for work item link types'

      value 'RELATED', 'Related type.', value: 'relates_to'
    end
  end
end

Types::WorkItems::RelatedLinkTypeEnum.prepend_mod_with('Types::WorkItems::RelatedLinkTypeEnum')
