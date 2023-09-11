# frozen_string_literal: true

module Users
  class TrackNamespaceVisitsWorker
    include ApplicationWorker

    feature_category :navigation
    data_consistency :delayed
    urgency :throttled
    idempotent!

    GROUPS = 'groups'
    PROJECTS = 'projects'

    def perform(entity_type, entity_id, user_id, time)
      return unless entity_id && user_id

      case entity_type
      when GROUPS
        unless GroupVisit.visited_around?(entity_id: entity_id, user_id: user_id, time: time)
          GroupVisit.create!(entity_id: entity_id, user_id: user_id, visited_at: time)
        end
      when PROJECTS
        unless ProjectVisit.visited_around?(entity_id: entity_id, user_id: user_id, time: time)
          ProjectVisit.create!(entity_id: entity_id, user_id: user_id, visited_at: time)
        end
      end
    end
  end
end
