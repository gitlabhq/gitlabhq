# frozen_string_literal: true

class AuditEvent < ApplicationRecord
  include CreatedAtFilterable
  include IgnorableColumns
  include BulkInsertSafe

  PARALLEL_PERSISTENCE_COLUMNS = [:author_name, :entity_path, :target_details].freeze

  ignore_column :updated_at, remove_with: '13.4', remove_after: '2020-09-22'

  serialize :details, Hash # rubocop:disable Cop/ActiveRecordSerialize

  belongs_to :user, foreign_key: :author_id

  validates :author_id, presence: true
  validates :entity_id, presence: true
  validates :entity_type, presence: true

  scope :by_entity_type, -> (entity_type) { where(entity_type: entity_type) }
  scope :by_entity_id, -> (entity_id) { where(entity_id: entity_id) }
  scope :by_author_id, -> (author_id) { where(author_id: author_id) }

  after_initialize :initialize_details
  # Note: The intention is to remove this once refactoring of AuditEvent
  # has proceeded further.
  #
  # See further details in the epic:
  # https://gitlab.com/groups/gitlab-org/-/epics/2765
  after_validation :parallel_persist

  def self.order_by(method)
    case method.to_s
    when 'created_asc'
      order(id: :asc)
    else
      order(id: :desc)
    end
  end

  def initialize_details
    self.details = {} if details.nil?
  end

  def author_name
    lazy_author.name
  end

  def formatted_details
    details.merge(details.slice(:from, :to).transform_values(&:to_s))
  end

  def lazy_author
    BatchLoader.for(author_id).batch(default_value: default_author_value) do |author_ids, loader|
      User.where(id: author_ids).find_each do |user|
        loader.call(user.id, user)
      end
    end
  end

  private

  def default_author_value
    ::Gitlab::Audit::NullAuthor.for(author_id, (self[:author_name] || details[:author_name]))
  end

  def parallel_persist
    PARALLEL_PERSISTENCE_COLUMNS.each { |col| self[col] = details[col] }
  end
end

AuditEvent.prepend_if_ee('EE::AuditEvent')
