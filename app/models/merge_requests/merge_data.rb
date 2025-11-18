# frozen_string_literal: true

module MergeRequests
  class MergeData < ApplicationRecord
    include PartitionedTable
    include ShaAttribute
    include Transitionable

    self.table_name = 'merge_requests_merge_data'
    self.primary_key = 'merge_request_id'

    partitioned_by :merge_request_id, strategy: :int_range, partition_size: 10_000_000

    MERGE_STATUSES = {
      unchecked: 0,
      preparing: 1,
      checking: 2,
      can_be_merged: 3,
      cannot_be_merged: 4,
      cannot_be_merged_recheck: 5,
      cannot_be_merged_rechecking: 6
    }.freeze

    belongs_to :merge_request, inverse_of: :merge_data
    belongs_to :project
    belongs_to :merge_user, class_name: 'User'

    validates :project, presence: true
    validates :merge_request, presence: true
    validates :merge_status, presence: true
    validates :merge_status, inclusion: { in: MERGE_STATUSES.values }

    sha_attribute :merge_commit_sha
    sha_attribute :merged_commit_sha
    sha_attribute :merge_ref_sha
    sha_attribute :squash_commit_sha
    sha_attribute :in_progress_merge_commit_sha

    serialize :merge_params, type: Hash # rubocop:disable Cop/ActiveRecordSerialize -- Extraction to a new table

    state_machine :merge_status, initial: :unchecked do
      event :mark_as_preparing do
        transition [:unchecked, :can_be_merged] => :preparing
      end

      event :mark_as_unchecked do
        transition [:preparing, :can_be_merged, :checking] => :unchecked
        transition [:cannot_be_merged, :cannot_be_merged_rechecking] => :cannot_be_merged_recheck
      end

      event :mark_as_checking do
        transition unchecked: :checking
        transition cannot_be_merged_recheck: :cannot_be_merged_rechecking
      end

      event :mark_as_mergeable do
        transition [:unchecked, :cannot_be_merged_recheck, :checking, :cannot_be_merged_rechecking] => :can_be_merged
      end

      event :mark_as_unmergeable do
        transition [:unchecked, :cannot_be_merged_recheck, :checking, :cannot_be_merged_rechecking] => :cannot_be_merged
      end

      state :preparing, value: MERGE_STATUSES[:preparing]
      state :unchecked, value: MERGE_STATUSES[:unchecked]
      state :cannot_be_merged_recheck, value: MERGE_STATUSES[:cannot_be_merged_recheck]
      state :checking, value: MERGE_STATUSES[:checking]
      state :cannot_be_merged_rechecking, value: MERGE_STATUSES[:cannot_be_merged_rechecking]
      state :can_be_merged, value: MERGE_STATUSES[:can_be_merged]
      state :cannot_be_merged, value: MERGE_STATUSES[:cannot_be_merged]

      around_transition do |merge_data, _transition, block|
        Gitlab::Timeless.timeless(merge_data, &block)
      end

      # TODO: Move before_transition and after_transition callbacks from MergeRequest
      #   when MergeRequest no longer handles merge_status transitions:

      def check_state?(merge_status)
        [:unchecked, :cannot_be_merged_recheck, :checking, :cannot_be_merged_rechecking].include?(merge_status.to_sym)
      end
    end

    # Returns current merge_status except it returns `cannot_be_merged_rechecking` as `checking`
    # to avoid exposing unnecessary internal state
    def public_merge_status
      cannot_be_merged_rechecking? || preparing? ? 'checking' : merge_status_name.to_s
    end
  end
end
