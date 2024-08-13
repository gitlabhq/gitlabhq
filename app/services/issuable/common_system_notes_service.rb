# frozen_string_literal: true

module Issuable
  class CommonSystemNotesService < ::BaseProjectService
    attr_reader :issuable, :is_update

    def execute(issuable, old_labels: [], old_milestone: nil, is_update: true)
      @issuable = issuable
      @is_update = is_update

      # We disable touch so that created system notes do not update
      # the noteable's updated_at field
      ApplicationRecord.no_touching do
        if is_update
          if issuable.previous_changes.include?('title')
            create_title_change_note(issuable.previous_changes['title'].first)
          end

          handle_description_change_note

          create_discussion_lock_note if issuable.previous_changes.include?('discussion_locked')
        end

        handle_time_tracking_note if issuable.is_a?(TimeTrackable)
        handle_start_date_or_due_date_change_note
        create_milestone_change_event(old_milestone) if issuable.previous_changes.include?('milestone_id')
        create_labels_note(old_labels) if old_labels && issuable.labels != old_labels
      end
    end

    private

    def handle_start_date_or_due_date_change_note
      # Type check needed as some issuables do their own date change handling for date fields other than due_date
      changed_dates =
        if issuable.is_a?(WorkItem) && issuable.dates_source.present?
          issuable.dates_source.previous_changes&.slice(*%w[due_date start_date])
        elsif issuable.is_a?(Issue)
          issuable.previous_changes&.slice(*%w[due_date start_date])
        else
          issuable.previous_changes.slice(:due_date)
        end

      create_start_date_or_due_date_note(changed_dates)
    end

    def handle_time_tracking_note
      estimate_updated = is_update && issuable.previous_changes.include?('time_estimate')
      estimate_set = !is_update && issuable.time_estimate != 0

      create_time_estimate_note if estimate_updated || estimate_set
      create_time_spent_note if issuable.time_spent?
    end

    def handle_description_change_note
      if issuable.previous_changes.include?('description')
        if issuable.tasks? && issuable.updated_tasks.any?
          create_task_status_note
        else
          # TODO: Show this note if non-task content was modified.
          # https://gitlab.com/gitlab-org/gitlab-foss/issues/33577
          create_description_change_note
        end
      end
    end

    def create_draft_note(old_title)
      return unless issuable.is_a?(MergeRequest)

      if MergeRequest.draft?(old_title) != issuable.draft?
        SystemNoteService.handle_merge_request_draft(issuable, issuable.project, current_user)
      end
    end

    def create_labels_note(old_labels)
      added_labels = issuable.labels - old_labels
      removed_labels = old_labels - issuable.labels

      ResourceEvents::ChangeLabelsService
        .new(issuable, current_user)
        .execute(added_labels: added_labels, removed_labels: removed_labels)
    end

    def create_title_change_note(old_title)
      create_draft_note(old_title)

      if issuable.draftless_title_changed(old_title)
        SystemNoteService.change_title(issuable, issuable.project, current_user, old_title)
      end
    end

    def create_description_change_note
      SystemNoteService.change_description(issuable, issuable.project, current_user)
    end

    def create_task_status_note
      issuable.updated_tasks.each do |task|
        SystemNoteService.change_task_status(issuable, issuable.project, current_user, task)
      end
    end

    def create_time_estimate_note
      SystemNoteService.change_time_estimate(issuable, issuable.project, current_user)
    end

    def create_time_spent_note
      SystemNoteService.change_time_spent(issuable, issuable.project, issuable.time_spent_user)
    end

    def create_milestone_change_event(old_milestone)
      ResourceEvents::ChangeMilestoneService.new(issuable, current_user, old_milestone: old_milestone)
        .execute
    end

    def create_start_date_or_due_date_note(changed_dates)
      return if changed_dates.blank?

      SystemNoteService.change_start_date_or_due_date(issuable, issuable.project, current_user, changed_dates)
    end

    def create_discussion_lock_note
      SystemNoteService.discussion_lock(issuable, current_user)
    end
  end
end

Issuable::CommonSystemNotesService.prepend_mod_with('Issuable::CommonSystemNotesService')
