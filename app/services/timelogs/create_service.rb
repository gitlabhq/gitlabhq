# frozen_string_literal: true

module Timelogs
  class CreateService < Timelogs::BaseService
    attr_accessor :issuable, :time_spent, :spent_at, :summary

    def initialize(issuable, time_spent, spent_at, summary, user)
      super(user)

      @issuable = issuable
      @time_spent = time_spent
      @spent_at = spent_at
      @summary = summary
    end

    def execute
      unless can?(current_user, :create_timelog, issuable)
        return error(
          _("%{issuable_class_name} doesn't exist or you don't have permission to add timelog to it.") % {
            issuable_class_name: issuable.nil? ? 'Issuable' : issuable.base_class_name
          }, 404)
      end

      return error(_("Spent at can't be a future date and time."), 404) if spent_at.future?
      return error(_("Time spent can't be zero."), 404) if time_spent == 0

      issue = issuable if issuable.is_a?(Issue)
      merge_request = issuable if issuable.is_a?(MergeRequest)

      timelog = Timelog.new(
        time_spent: time_spent,
        spent_at: spent_at,
        summary: summary,
        user: current_user,
        issue: issue,
        merge_request: merge_request,
        note: nil
      )

      old_associations = { total_time_spent: issuable.total_time_spent }

      if !timelog.save
        error_in_save(timelog)
      else
        issuable.reset

        SystemNoteService.created_timelog(issuable, issuable.project, current_user, timelog)

        issuable_base_service.execute_hooks(issuable, 'update', old_associations: old_associations)

        success(timelog)
      end
    end

    private

    def issuable_base_service
      if issuable.is_a?(Issue)
        Issues::BaseService.new(
          container: issuable.project,
          current_user: current_user
        )
      else
        MergeRequests::BaseService.new(
          project: issuable.project,
          current_user: current_user
        )
      end
    end
  end
end
