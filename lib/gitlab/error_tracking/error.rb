# frozen_string_literal: true

module Gitlab
  module ErrorTracking
    class Error
      include ActiveModel::Model
      include GlobalID::Identification

      attr_accessor :id, :title, :type, :user_count, :count,
        :first_seen, :last_seen, :message, :culprit,
        :external_url, :project_id, :project_name, :project_slug,
        :short_id, :status, :frequency

      def self.declarative_policy_class
        'ErrorTracking::BasePolicy'
      end
    end
  end
end
