# frozen_string_literal: true

class BackfillStageEventHash < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  BATCH_SIZE = 100
  EVENT_ID_IDENTIFIER_MAPPING = {
    1 => :issue_created,
    2 => :issue_first_mentioned_in_commit,
    3 => :issue_closed,
    4 => :issue_first_added_to_board,
    5 => :issue_first_associated_with_milestone,
    7 => :issue_last_edited,
    8 => :issue_label_added,
    9 => :issue_label_removed,
    10 => :issue_deployed_to_production,
    100 => :merge_request_created,
    101 => :merge_request_first_deployed_to_production,
    102 => :merge_request_last_build_finished,
    103 => :merge_request_last_build_started,
    104 => :merge_request_merged,
    105 => :merge_request_closed,
    106 => :merge_request_last_edited,
    107 => :merge_request_label_added,
    108 => :merge_request_label_removed,
    109 => :merge_request_first_commit_at,
    1000 => :code_stage_start,
    1001 => :issue_stage_end,
    1002 => :plan_stage_start
  }.freeze

  LABEL_BASED_EVENTS = Set.new([8, 9, 107, 108]).freeze

  class GroupStage < ActiveRecord::Base
    include EachBatch

    self.table_name = 'analytics_cycle_analytics_group_stages'
  end

  class ProjectStage < ActiveRecord::Base
    include EachBatch

    self.table_name = 'analytics_cycle_analytics_project_stages'
  end

  class StageEventHash < ActiveRecord::Base
    self.table_name = 'analytics_cycle_analytics_stage_event_hashes'
  end

  def up
    GroupStage.reset_column_information
    ProjectStage.reset_column_information
    StageEventHash.reset_column_information

    update_stage_table(GroupStage)
    update_stage_table(ProjectStage)

    add_not_null_constraint :analytics_cycle_analytics_group_stages, :stage_event_hash_id
    add_not_null_constraint :analytics_cycle_analytics_project_stages, :stage_event_hash_id
  end

  def down
    remove_not_null_constraint :analytics_cycle_analytics_group_stages, :stage_event_hash_id
    remove_not_null_constraint :analytics_cycle_analytics_project_stages, :stage_event_hash_id
  end

  private

  def update_stage_table(klass)
    klass.each_batch(of: BATCH_SIZE) do |relation|
      klass.transaction do
        records = relation.where(stage_event_hash_id: nil).lock!.to_a # prevent concurrent modification (unlikely to happen)
        records = delete_invalid_records(records)
        next if records.empty?

        hashes_by_stage = records.index_with { |stage| calculate_stage_events_hash(stage) }
        hashes = hashes_by_stage.values.uniq

        StageEventHash.insert_all(hashes.map { |hash| { hash_sha256: hash } })

        stage_event_hashes_by_hash = StageEventHash.where(hash_sha256: hashes).index_by(&:hash_sha256)
        records.each do |stage|
          stage.update!(stage_event_hash_id: stage_event_hashes_by_hash[hashes_by_stage[stage]].id)
        end
      end
    end
  end

  def calculate_stage_events_hash(stage)
    start_event_hash = calculate_event_hash(stage.start_event_identifier, stage.start_event_label_id)
    end_event_hash = calculate_event_hash(stage.end_event_identifier, stage.end_event_label_id)

    Digest::SHA256.hexdigest("#{start_event_hash}-#{end_event_hash}")
  end

  def calculate_event_hash(event_identifier, label_id = nil)
    str = EVENT_ID_IDENTIFIER_MAPPING.fetch(event_identifier).to_s
    str << "-#{label_id}" if LABEL_BASED_EVENTS.include?(event_identifier)

    Digest::SHA256.hexdigest(str)
  end

  # Invalid records are safe to delete, since they are not working properly anyway
  def delete_invalid_records(records)
    to_be_deleted = records.select do |record|
      EVENT_ID_IDENTIFIER_MAPPING[record.start_event_identifier].nil? ||
        EVENT_ID_IDENTIFIER_MAPPING[record.end_event_identifier].nil?
    end

    to_be_deleted.each(&:delete)
    records - to_be_deleted
  end
end
