# frozen_string_literal: true

module Import
  class SourceUser < ApplicationRecord
    include Gitlab::SQL::Pattern
    include EachBatch

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
    validates :source_user_identifier, uniqueness: { scope: [:namespace_id, :source_hostname, :import_type] }
    validates :placeholder_user_id, presence: true, unless: :completed?
    validates :reassignment_token, absence: true, unless: :awaiting_approval?
    validates :reassignment_token, length: { is: 32 }, if: :awaiting_approval?
    validates :reassign_to_user_id, presence: true, if: -> {
                                                          awaiting_approval? || reassignment_in_progress? || completed?
                                                        }
    validates :reassign_to_user_id, absence: true, if: -> { pending_reassignment? || keep_as_placeholder? }
    validates :reassign_to_user_id, uniqueness: {
      scope: [:namespace_id, :source_hostname, :import_type],
      allow_nil: true,
      message: ->(_object, _data) {
        s_('Import|already assigned to another placeholder')
      }
    }
    validate :validate_source_hostname

    scope :for_namespace, ->(namespace_id) { where(namespace_id: namespace_id) }
    scope :by_source_hostname, ->(source_hostname) { where(source_hostname: source_hostname) }
    scope :by_import_type, ->(import_type) { where(import_type: import_type) }
    scope :by_statuses, ->(statuses) { where(status: statuses) }
    scope :awaiting_reassignment, -> { where(status: [0, 1, 2, 3, 4]) }
    scope :reassigned, -> { where(status: [5, 6]) }

    STATUSES = {
      pending_reassignment: 0,
      awaiting_approval: 1,
      reassignment_in_progress: 2,
      rejected: 3,
      failed: 4,
      completed: 5,
      keep_as_placeholder: 6
    }.freeze

    ACCEPTED_STATUSES = %i[reassignment_in_progress completed failed].freeze
    REASSIGNABLE_STATUSES = %i[pending_reassignment rejected].freeze
    CANCELABLE_STATUSES = %i[awaiting_approval rejected].freeze

    state_machine :status, initial: :pending_reassignment do
      STATUSES.each do |status_name, value|
        state status_name, value: value
      end

      before_transition awaiting_approval: any do |source_user|
        source_user.reassignment_token = nil
      end

      before_transition any => :awaiting_approval do |source_user|
        source_user.reassignment_token = SecureRandom.hex
      end

      event :reassign do
        transition REASSIGNABLE_STATUSES => :awaiting_approval
      end

      event :cancel_reassignment do
        transition CANCELABLE_STATUSES => :pending_reassignment
      end

      event :keep_as_placeholder do
        transition REASSIGNABLE_STATUSES => :keep_as_placeholder
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

      def namespace_placeholder_user_count(namespace, limit:)
        for_namespace(namespace).distinct.limit(limit).count(:placeholder_user_id) -
          (namespace.namespace_import_user.present? ? 1 : 0)
      end

      def source_users_with_missing_information(namespace:, source_hostname:, import_type:)
        for_namespace(namespace)
          .by_source_hostname(source_hostname)
          .by_import_type(import_type)
          .and(
            where(source_name: nil).or(where(source_username: nil))
          )
      end
    end

    def mapped_user
      accepted_status? ? reassign_to_user : placeholder_user
    end

    def mapped_user_id
      accepted_status? ? reassign_to_user_id : placeholder_user_id
    end

    def accepted_status?
      STATUSES.slice(*ACCEPTED_STATUSES).value?(status)
    end

    def reassignable_status?
      STATUSES.slice(*REASSIGNABLE_STATUSES).value?(status)
    end

    def cancelable_status?
      STATUSES.slice(*CANCELABLE_STATUSES).value?(status)
    end

    def validate_source_hostname
      return unless source_hostname

      uri = Gitlab::Utils.parse_url(source_hostname)

      return if uri && uri.scheme && uri.host && uri.path.blank?

      errors.add(:source_hostname, :invalid, message: 'must contain scheme and host, and not path')
    end
  end
end
