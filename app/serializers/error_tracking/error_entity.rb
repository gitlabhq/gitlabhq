# frozen_string_literal: true

module ErrorTracking
  class ErrorEntity < Grape::Entity
    expose :id do |error|
      error.id.to_s
    end

    expose :title, :type, :user_count, :count,
      :first_seen, :last_seen, :message, :culprit,
      :external_url, :project_id, :project_name, :project_slug,
      :short_id, :status, :frequency
  end
end
