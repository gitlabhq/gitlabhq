# frozen_string_literal: true

module Users
  module Visitable
    extend ActiveSupport::Concern

    included do
      def self.visited_around?(entity_id:, user_id:, time:)
        visits_around(entity_id: entity_id, user_id: user_id, time: time).any?
      end

      def self.visits_around(entity_id:, user_id:, time:)
        time = time.to_datetime
        where(entity_id: entity_id, user_id: user_id, visited_at: (time - 15.minutes)..(time + 15.minutes))
      end
    end
  end
end
