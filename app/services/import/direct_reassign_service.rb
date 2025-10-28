# frozen_string_literal: true

# Reassigns contributions from placeholder users to real users without creating
# placeholder references.
#
# This service processes all eligible models with proper database indexes,
# updating user ID associations in batches for optimal performance.
#
# == Batch Processing Strategy
#
# 1. *Primary approach*: Uses `update_all` for efficient batch updates
# 2. *Fallback approach*: When unique constraints cause failures, falls back to
#    individual record updates with duplicate record cleanup
#
# == Handling Unique Constraint Violations
#
# Unique constraint errors can occur when a contribution already exists for the
# reassignee user on a has_many association before reassignment begins.
#
# *Example scenario*:
# - A merge request approval is imported and assigned to a placeholder user
# - The reassignee user later approves the same merge request
# - During reassignment, the placeholder user's approval cannot be transferred
#   to the reassignee as it would create a duplicate approval
# - In this case, the placeholder user's approval is deleted

module Import
  class DirectReassignService
    REASSIGN_BATCH_LIMIT = 100
    BATCH_SLEEP = 3

    MODEL_LIST = {
      "Approval" => ["user_id"],
      "AwardEmoji" => ["user_id"],
      "Ci::Pipeline" => ["user_id"],
      "Ci::PipelineSchedule" => ["owner_id"],
      "CommitStatus" => ["user_id"],
      "DesignManagement::Version" => ["author_id"],
      "Epic" => %w[author_id assignee_id last_edited_by_id closed_by_id],
      "Event" => ["author_id"],
      "Issue" => %w[author_id updated_by_id closed_by_id],
      "IssueAssignee" => ["user_id"],
      "List" => ['user_id'],
      "MergeRequest::Metrics" => %w[merged_by_id latest_closed_by_id],
      "MergeRequest" => %w[author_id updated_by_id merge_user_id],
      "MergeRequestAssignee" => ["user_id"],
      "MergeRequestReviewer" => ["user_id"],
      "Note" => %w[author_id],
      "ProtectedBranch::MergeAccessLevel" => ["user_id"],
      "ProtectedBranch::PushAccessLevel" => ["user_id"],
      "ProtectedTag::CreateAccessLevel" => ["user_id"],
      "Release" => ["author_id"],
      "ResourceLabelEvent" => ["user_id"],
      "ResourceMilestoneEvent" => ["user_id"],
      "ResourceStateEvent" => ["user_id"],
      "Snippet" => ["author_id"],
      "Timelog" => ["user_id"],
      "Vulnerability" => %w[author_id resolved_by_id dismissed_by_id confirmed_by_id]
    }.freeze

    # Lists all models and attributes that are imported, reference users, and have an
    # index for the attribute
    #
    # Overridden in EE
    def self.model_list
      MODEL_LIST
    end

    def initialize(import_source_user, sleep_time: BATCH_SLEEP)
      @import_source_user = import_source_user
      @reassigned_by_user = import_source_user.reassigned_by_user
      @execution_tracker = Gitlab::Utils::ExecutionTracker.new
      @sleep_time = sleep_time
    end

    def execute
      return if Feature.disabled?(:user_mapping_direct_reassignment, reassigned_by_user)
      return unless import_source_user.placeholder_user.placeholder?

      self.class.model_list.each do |model, columns|
        columns.each do |column|
          direct_reassign_model_user_references(model, column)
        end
      end
    end

    private

    attr_accessor :import_source_user, :reassigned_by_user, :sleep_time, :execution_tracker

    # @param model [String]
    # @param column [String]
    def direct_reassign_model_user_references(model, column)
      model_class = model.constantize

      loop do
        contributions = find_batch_of_contributions(model_class, column)

        begin
          # First, try to update user references in batches
          update_count = model_class.transaction do
            contributions.update_all(column => import_source_user.reassign_to_user_id)
          end

          break if update_count == 0
        rescue ActiveRecord::RecordNotUnique
          # Fallback to individual reassignment
          contributions.each do |contribution|
            reassign_single_contribution(model_class, contribution, column)
          end
        end

        if execution_tracker.over_limit?
          raise Gitlab::Utils::ExecutionTracker::ExecutionTimeOutError, 'Execution timeout'
        end

        Kernel.sleep sleep_time
      end
    end

    # @param model [String]
    # @param column [String]
    # rubocop:disable CodeReuse/ActiveRecord -- this query is performed in several distinct model
    def find_batch_of_contributions(model_class, column)
      model_class.where(column => import_source_user.placeholder_user_id)
                .limit(REASSIGN_BATCH_LIMIT)
    end
    # rubocop:enable CodeReuse/ActiveRecord

    def reassign_single_contribution(model_class, contribution, column)
      model_class.transaction do
        contribution.update_column(column, import_source_user.reassign_to_user_id)
      end
    rescue ActiveRecord::RecordNotUnique
      log_warn("Destroying contribution due to uniqueness constraint",
        to_param: contribution.to_param,
        model: contribution.class.name)

      contribution.destroy!
    end

    def logger
      Framework::Logger
    end

    def log_warn(...)
      logger.warn(logger_params(...))
    end

    def logger_params(message, **params)
      params.merge(
        message: message,
        source_user_id: import_source_user.id
      )
    end
  end
end

Import::DirectReassignService.prepend_mod
