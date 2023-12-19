# frozen_string_literal: true

module ServiceDesk
  class CustomEmailVerification < ApplicationRecord
    TIMEFRAME = 30.minutes
    STATES = { started: 0, finished: 1, failed: 2 }.freeze

    enum error: {
      incorrect_token: 0,
      incorrect_from: 1,
      mail_not_received_within_timeframe: 2,
      invalid_credentials: 3,
      smtp_host_issue: 4,
      read_timeout: 5,
      incorrect_forwarding_target: 6
    }

    attr_encrypted :token,
      mode: :per_attribute_iv,
      algorithm: 'aes-256-gcm',
      key: Settings.attr_encrypted_db_key_base_32,
      encode: false,
      encode_iv: false

    belongs_to :project
    belongs_to :triggerer, class_name: 'User', optional: true

    validates :project, presence: true
    validates :state, presence: true

    scope :overdue, -> { where('triggered_at < ?', TIMEFRAME.ago) }

    delegate :service_desk_setting, to: :project

    state_machine :state do
      state :started do
        validates :token, presence: true, length: { is: 12 }
        validates :triggerer, presence: true
        validates :triggered_at, presence: true
        validates :error, absence: true
      end

      state :finished do
        validates :token, absence: true
        validates :error, absence: true
      end

      state :failed do
        validates :token, absence: true
        validates :error, presence: true
      end

      event :mark_as_started do
        transition all => :started
      end

      event :mark_as_finished do
        transition started: :finished
      end

      event :mark_as_failed do
        transition all => :failed
      end

      before_transition any => :started do |verification, transition|
        triggerer = transition.args.first

        verification.triggerer = triggerer
        verification.token = verification.class.generate_token
        verification.triggered_at = Time.current
        verification.error = nil
      end

      before_transition started: :finished do |verification|
        verification.token = nil
      end

      before_transition started: :failed do |verification, transition|
        error = transition.args.first

        verification.error = error
        verification.token = nil
      end

      # Supress warning:
      # both enum and its state_machine have defined a different default for "state".
      # State machine uses `nil` and the enum should use the same.
      def owner_class_attribute_default
        nil
      end
    end

    # Needs to be below `state_machine` definition to suppress
    # its method override warnings
    enum state: STATES

    class << self
      def generate_token
        SecureRandom.alphanumeric(12)
      end
    end

    def accepted_until
      return unless started?
      return unless triggered_at.present?

      TIMEFRAME.since(triggered_at)
    end

    def in_timeframe?
      return false unless started?

      !!accepted_until&.future?
    end
  end
end
