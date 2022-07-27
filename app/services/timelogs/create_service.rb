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

      if !timelog.save
        error_in_save(timelog)
      else
        SystemNoteService.created_timelog(issuable, issuable.project, current_user, timelog)
        success(timelog)
      end
    end
  end
end
