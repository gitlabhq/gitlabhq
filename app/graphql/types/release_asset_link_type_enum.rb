# frozen_string_literal: true

module Types
  class ReleaseAssetLinkTypeEnum < BaseEnum
    graphql_name 'ReleaseAssetLinkType'
    description 'Type of the link: `other`, `runbook`, `image`, `package`'

    ::Releases::Link.link_types.keys.each do |link_type|
      value link_type.upcase, value: link_type, description: "#{link_type.titleize} link type"
    end
  end
end
