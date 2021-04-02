# frozen_string_literal: true

module Analytics
  module UniqueVisitsHelper
    extend ActiveSupport::Concern

    def visitor_id
      return cookies[:visitor_id] if cookies[:visitor_id].present?
      return unless current_user

      uuid = SecureRandom.uuid
      cookies[:visitor_id] = { value: uuid, expires: 24.months }
      uuid
    end

    def track_visit(target_id)
      return unless visitor_id

      Gitlab::Analytics::UniqueVisits.new.track_visit(target_id, values: visitor_id)
    end

    class_methods do
      def track_unique_visits(controller_actions, target_id:)
        after_action only: controller_actions, if: -> { request.format.html? && request.headers['DNT'] != '1' } do
          track_visit(target_id)
        end
      end
    end
  end
end
