# frozen_string_literal: true

class DropPartitionedIndexInSentNotifications < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  TABLE_NAME = :sent_notifications_7abbf02cb6
  INDEX_DEFINITIONS = [
    [:issue_email_participant_id, { name: 'idx_p_sent_notifications_on_issue_email_participant_id' }],
    [:namespace_id, { name: 'idx_p_sent_notifications_on_namespace_id' }],
    [
      [:noteable_id, :id],
      { name: 'idx_p_sent_notifications_on_noteable_type_noteable_id_and_id', where: "noteable_type = 'Issue'" }
    ]
  ].freeze

  milestone '18.3'
  disable_ddl_transaction!

  def up
    INDEX_DEFINITIONS.each do |_columns, options| # rubocop:disable Style/HashEachMethods -- not a hash
      remove_concurrent_partitioned_index_by_name(TABLE_NAME, options[:name])
    end
  end

  def down
    INDEX_DEFINITIONS.each do |columns, options|
      add_concurrent_partitioned_index(TABLE_NAME, columns, options)
    end
  end
end
