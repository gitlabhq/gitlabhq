# frozen_string_literal: true

module Import
  class SourceUser < ApplicationRecord
    include Gitlab::SQL::Pattern

    self.table_name = 'import_source_users'

    SORT_ORDERS = {
      source_name_asc: { order_by: 'source_name', sort: 'asc' },
      source_name_desc: { order_by: 'source_name', sort: 'desc' },
      status_asc: { order_by: 'status', sort: 'asc' },
      status_desc: { order_by: 'status', sort: 'desc' }
    }.freeze

    belongs_to :placeholder_user, class_name: 'User', optional: true
    belongs_to :reassign_to_user, class_name: 'User', optional: true
    belongs_to :reassigned_by_user, class_name: 'User', optional: true
    belongs_to :namespace

    validates :namespace_id, :import_type, :source_hostname, :source_user_identifier, :status, presence: true

    scope :for_namespace, ->(namespace_id) { where(namespace_id: namespace_id) }
    scope :by_statuses, ->(statuses) { where(status: statuses) }
    scope :awaiting_reassignment, -> { where(status: [0, 1, 2, 3, 4]) }
    scope :reassigned, -> { where(status: [5, 6]) }

    state_machine :status, initial: :pending_reassignment do
      state :pending_reassignment, value: 0
      state :awaiting_approval, value: 1
      state :reassignment_in_progress, value: 2
      state :rejected, value: 3
      state :failed, value: 4
      state :completed, value: 5
      state :keep_as_placeholder, value: 6

      event :reassign do
        transition [:pending_reassignment, :rejected] => :awaiting_approval
      end

      event :cancel_reassignment do
        transition [:awaiting_approval, :rejected] => :pending_reassignment
      end

      event :keep_as_placeholder do
        transition [:pending_reassignment, :rejected] => :keep_as_placeholder
      end

      event :accept do
        transition awaiting_approval: :reassignment_in_progress
      end

      event :reject do
        transition awaiting_approval: :rejected
      end

      event :complete do
        transition reassignment_in_progress: :completed
      end

      event :fail_reassignment do
        transition reassignment_in_progress: :failed
      end

      after_transition any => [:pending_reassignment, :rejected, :keep_as_placeholder] do |status|
        status.update!(reassign_to_user: nil)
      end
    end

    class << self
      def find_source_user(source_user_identifier:, namespace:, source_hostname:, import_type:)
        return unless namespace

        find_by(
          source_user_identifier: source_user_identifier,
          namespace_id: namespace.id,
          source_hostname: source_hostname,
          import_type: import_type
        )
      end

      def search(query)
        return none unless query.is_a?(String)

        fuzzy_search(query, [:source_name, :source_username])
      end

      def sort_by_attribute(method)
        sort_order = SORT_ORDERS[method&.to_sym] || SORT_ORDERS[:source_name_asc]

        reorder(sort_order[:order_by] => sort_order[:sort])
      end
    end

    def accepted_reassign_to_user
      reassign_to_user if accepted_status?
    end

    def accepted_status?
      reassignment_in_progress? || completed? || failed?
    end

    def reassignable_status?
      pending_reassignment? || rejected?
    end

    def cancelable_status?
      awaiting_approval? || rejected?
    end
  end
end
