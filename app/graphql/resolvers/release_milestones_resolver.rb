# frozen_string_literal: true

module Resolvers
  class ReleaseMilestonesResolver < BaseResolver
    type Types::MilestoneType.connection_type, null: true

    alias_method :release, :object

    def resolve(**args)
      offset_pagination(release.milestones.order_by_dates_and_title)
    end
  end
end
