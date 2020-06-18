# frozen_string_literal: true

module Types
  class ReleaseLinkTypeEnum < BaseEnum
    graphql_name 'ReleaseLinkType'
    description 'Type of the link: `other`, `runbook`, `image`, `package`; defaults to `other`'

    ::Releases::Link.link_types.keys.each do |link_type|
      value link_type.upcase, value: link_type, description: "#{link_type.titleize} link type"
    end
  end
end
