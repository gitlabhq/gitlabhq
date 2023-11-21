# frozen_string_literal: true

class AuditEvent < ApplicationRecord
  include AfterCommitQueue
  include CreatedAtFilterable
  include BulkInsertSafe
  include EachBatch
  include PartitionedTable

  PARALLEL_PERSISTENCE_COLUMNS = [
    :author_name,
    :entity_path,
    :target_details,
    :target_type,
    :target_id
  ].freeze

  self.primary_key = :id

  partitioned_by :created_at, strategy: :monthly

  serialize :details, Hash # rubocop:disable Cop/ActiveRecordSerialize

  belongs_to :user, foreign_key: :author_id, inverse_of: :audit_events

  validates :author_id, presence: true
  validates :entity_id, presence: true
  validates :entity_type, presence: true
  validates :ip_address, ip_address: true

  scope :by_entity_type, ->(entity_type) { where(entity_type: entity_type) }
  scope :by_entity_id, ->(entity_id) { where(entity_id: entity_id) }
  scope :by_author_id, ->(author_id) { where(author_id: author_id) }
  scope :by_entity_username, ->(username) { where(entity_id: find_user_id(username)) }
  scope :by_author_username, ->(username) { where(author_id: find_user_id(username)) }

  after_initialize :initialize_details

  before_validation :sanitize_message

  # Note: The intention is to remove this once refactoring of AuditEvent
  # has proceeded further.
  #
  # See further details in the epic:
  # https://gitlab.com/groups/gitlab-org/-/epics/2765
  after_validation :parallel_persist

  def self.supported_keyset_orderings
    { id: [:desc] }
  end

  def self.order_by(method)
    case method.to_s
    when 'created_asc'
      order(id: :asc)
    else
      order(id: :desc)
    end
  end

  def initialize_details
    return unless has_attribute?(:details)

    self.details = {} if details&.nil?
  end

  def author_name
    author&.name
  end

  def formatted_details
    details
      .merge(details.slice(:from, :to).transform_values(&:to_s))
      .merge(author_email: author.try(:email))
  end

  def author
    lazy_author&.itself.presence || default_author_value
  end

  def lazy_author
    BatchLoader.for(author_id).batch do |author_ids, loader|
      User.select(:id, :name, :username, :email).where(id: author_ids).find_each do |user|
        loader.call(user.id, user)
      end
    end
  end

  def as_json(options = {})
    super(options).tap do |json|
      json['ip_address'] = ip_address.to_s
    end
  end

  def target_type
    super || details[:target_type]
  end

  def target_id
    details[:target_id]
  end

  def target_details
    super || details[:target_details]
  end

  private

  def sanitize_message
    message = details[:custom_message]

    return unless message

    self.details = details.merge(custom_message: Sanitize.clean(message))
  end

  def default_author_value
    ::Gitlab::Audit::NullAuthor.for(author_id, self)
  end

  def parallel_persist
    PARALLEL_PERSISTENCE_COLUMNS.each do |name|
      original = self[name] || details[name]
      next unless original

      self[name] = details[name] = original
    end
  end

  def self.find_user_id(username)
    User.find_by_username(username)&.id
  end
end

AuditEvent.prepend_mod_with('AuditEvent')
