# frozen_string_literal: true

module Import
  module Offline
    class Export < ApplicationRecord
      self.table_name = 'import_offline_exports'

      KNOWN_IMPORT_HOSTS = %w[github.com bitbucket.org gitea.com].freeze

      belongs_to :user
      belongs_to :organization, class_name: 'Organizations::Organization'

      has_many :bulk_import_exports, class_name: 'BulkImports::Export', inverse_of: :offline_export

      validates :source_hostname, :status, presence: true
      validate :validate_source_hostname

      state_machine :status, initial: :created do
        state :created, value: 0
        state :started, value: 1
        state :finished, value: 2
        state :failed, value: -1

        event :start do
          transition created: :started
        end

        event :finish do
          transition started: :finished
        end

        event :fail_op do
          transition any => :failed
        end
      end

      def validate_source_hostname
        uri = Gitlab::Utils.parse_url(source_hostname)

        if KNOWN_IMPORT_HOSTS.include?(uri&.host)
          return errors.add(:source_hostname, :invalid, message: 'must not be the host of a known import source')
        end

        return if uri && uri.scheme && uri.host && uri.path.blank? && uri.query.blank?

        errors.add(:source_hostname, :invalid, message: 'must contain scheme and host, and not path or query')
      end
    end
  end
end
