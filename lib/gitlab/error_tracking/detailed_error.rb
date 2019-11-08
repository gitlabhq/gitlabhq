# frozen_string_literal: true

module Gitlab
  module ErrorTracking
    class DetailedError
      include ActiveModel::Model

      attr_accessor :count,
                    :culprit,
                    :external_base_url,
                    :external_url,
                    :first_release_last_commit,
                    :first_release_short_version,
                    :first_seen,
                    :frequency,
                    :id,
                    :last_release_last_commit,
                    :last_release_short_version,
                    :last_seen,
                    :message,
                    :project_id,
                    :project_name,
                    :project_slug,
                    :short_id,
                    :status,
                    :title,
                    :type,
                    :user_count
    end
  end
end
