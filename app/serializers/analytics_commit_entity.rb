# frozen_string_literal: true

class AnalyticsCommitEntity < CommitEntity
  include EntityDateHelper

  expose :short_id, as: :short_sha

  expose :total_time do |commit|
    distance_of_time_as_hash(request.total_time.to_f)
  end

  unexpose :author_name
  unexpose :author_email
  unexpose :message
end
