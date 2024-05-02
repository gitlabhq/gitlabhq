# frozen_string_literal: true

module Resolvers
  class GroupReleasesResolver < BaseResolver
    type Types::ReleaseType.connection_type, null: true

    argument :sort, Types::GroupReleaseSortEnum,
      required: false, default_value: :released_at_desc,
      description: 'Sort group releases by given criteria.'

    alias_method :group, :object

    # GroupReleasesFinder only supports sorting by `released_at`
    SORT_TO_PARAMS_MAP = {
      released_at_desc: { sort: 'desc' },
      released_at_asc: { sort: 'asc' }
    }.freeze

    def resolve(sort:)
      releases = Releases::GroupReleasesFinder.new(
        group,
        current_user,
        SORT_TO_PARAMS_MAP[sort]
      ).execute
      # fix ordering problem with GroupReleasesFinder and keyset pagination
      # See more on https://gitlab.com/gitlab-org/gitlab/-/issues/378160
      offset_pagination(releases)
    end
  end
end
