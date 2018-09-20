# frozen_string_literal: true

module Geo
  module Eventable
    extend ActiveSupport::Concern
    include ::EachBatch

    included do
      has_one :geo_event_log, class_name: 'Geo::EventLog'
    end

    class_methods do
      def up_to_event(geo_event_log_id)
        joins(:geo_event_log)
          .where(Geo::EventLog.arel_table[:id].lteq(geo_event_log_id))
      end

      def delete_with_limit(limit)
        ::Gitlab::Database::Subquery.self_join(limit(limit)).delete_all
      end
    end
  end
end
