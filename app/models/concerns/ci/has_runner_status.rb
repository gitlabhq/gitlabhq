# frozen_string_literal: true

module Ci
  module HasRunnerStatus
    extend ActiveSupport::Concern

    included do
      scope :offline, -> { where(contacted_at: ..online_contact_time_deadline) }
      scope :never_contacted, -> { where(contacted_at: nil) }
      scope :online, -> { where(arel_table[:contacted_at].gt(online_contact_time_deadline)) }

      scope :with_status, ->(status) do
        return all if available_statuses.exclude?(status.to_s)

        public_send(status) # rubocop:disable GitlabSecurity/PublicSend -- safe to call
      end
    end

    class_methods do
      def available_statuses
        self::AVAILABLE_STATUSES_INCL_DEPRECATED
      end

      def online_contact_time_deadline
        raise NotImplementedError
      end

      def stale_deadline
        raise NotImplementedError
      end
    end

    def status
      return :stale if stale?
      return :never_contacted unless finished_creation_state?

      online? ? :online : :offline
    end

    def online?
      contacted_at && contacted_at > self.class.online_contact_time_deadline
    end

    def stale?
      return false unless created_at

      [created_at, contacted_at].compact.max <= self.class.stale_deadline
    end
  end
end
