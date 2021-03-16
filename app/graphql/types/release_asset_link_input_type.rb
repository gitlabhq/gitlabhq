# frozen_string_literal: true

module Types
  class ReleaseAssetLinkInputType < BaseInputObject
    graphql_name 'ReleaseAssetLinkInput'
    description 'Fields that are available when modifying a release asset link'

    include Types::ReleaseAssetLinkSharedInputArguments
  end
end
