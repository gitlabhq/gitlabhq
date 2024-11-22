# frozen_string_literal: true

module Emails
  module MergeRequests
    extend ActiveSupport::Concern

    included do
      override_layout_lookup_table.merge!({
        merge_when_pipeline_succeeds_email: 'mailer',
        approved_merge_request_email: 'mailer',
        unapproved_merge_request_email: 'mailer'
      })
    end

    def new_merge_request_email(recipient_id, merge_request_id, reason = nil)
      setup_merge_request_mail(merge_request_id, recipient_id, present: true)

      mail_new_thread(@merge_request, merge_request_thread_options(@merge_request.author_id, reason))
    end

    def new_mention_in_merge_request_email(recipient_id, merge_request_id, updated_by_user_id, reason = nil)
      setup_merge_request_mail(merge_request_id, recipient_id, present: true)

      mail_answer_thread(@merge_request, merge_request_thread_options(updated_by_user_id, reason))
    end

    # existing_commits - an array containing the first and last commits
    def push_to_merge_request_email(
      recipient_id,
      merge_request_id,
      updated_by_user_id,
      reason = nil,
      new_commits:,
      total_new_commits_count:,
      existing_commits:,
      total_existing_commits_count:
    )
      setup_merge_request_mail(merge_request_id, recipient_id)

      @new_commits = new_commits
      @total_new_commits_count = total_new_commits_count
      @total_stripped_new_commits_count = @total_new_commits_count - @new_commits.length

      @existing_commits = existing_commits
      @total_existing_commits_count = total_existing_commits_count

      @updated_by_user = User.find(updated_by_user_id)

      mail_answer_thread(@merge_request, merge_request_thread_options(updated_by_user_id, reason))
    end

    def change_in_merge_request_draft_status_email(recipient_id, merge_request_id, updated_by_user_id, reason = nil)
      setup_merge_request_mail(merge_request_id, recipient_id)

      @updated_by_user = User.find(updated_by_user_id)

      mail_answer_thread(@merge_request, merge_request_thread_options(updated_by_user_id, reason))
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def reassigned_merge_request_email(
      recipient_id,
      merge_request_id,
      previous_assignee_ids,
      updated_by_user_id,
      reason = nil
    )
      setup_merge_request_mail(merge_request_id, recipient_id)

      previous_assignees = []
      previous_assignees = User.where(id: previous_assignee_ids) if previous_assignee_ids.any?
      @added_assignees = @merge_request.assignees.map(&:name) - previous_assignees.map(&:name)
      @removed_assignees = previous_assignees.map(&:name) - @merge_request.assignees.map(&:name)

      mail_answer_thread(@merge_request, merge_request_thread_options(updated_by_user_id, reason))
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def changed_reviewer_of_merge_request_email(
      recipient_id,
      merge_request_id,
      previous_reviewer_ids,
      updated_by_user_id,
      reason = nil
    )
      setup_merge_request_mail(merge_request_id, recipient_id)

      @previous_reviewers = []
      @previous_reviewers = User.where(id: previous_reviewer_ids) if previous_reviewer_ids.any?
      @updated_by_user = User.find(updated_by_user_id)

      mail_answer_thread(@merge_request, merge_request_thread_options(updated_by_user_id, reason))
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def relabeled_merge_request_email(recipient_id, merge_request_id, label_names, updated_by_user_id, reason = nil)
      setup_merge_request_mail(merge_request_id, recipient_id)

      @label_names = label_names
      @labels_url = project_labels_url(@project, subscribed: true)
      mail_answer_thread(@merge_request, merge_request_thread_options(updated_by_user_id, reason))
    end

    def removed_milestone_merge_request_email(recipient_id, merge_request_id, updated_by_user_id, reason = nil)
      setup_merge_request_mail(merge_request_id, recipient_id)

      mail_answer_thread(@merge_request, merge_request_thread_options(updated_by_user_id, reason))
    end

    def changed_milestone_merge_request_email(
      recipient_id,
      merge_request_id,
      milestone,
      updated_by_user_id,
      reason = nil
    )
      setup_merge_request_mail(merge_request_id, recipient_id)

      @milestone = milestone
      @milestone_url = milestone_url(@milestone)
      mail_answer_thread(@merge_request, merge_request_thread_options(updated_by_user_id, reason).merge({
        template_name: 'changed_milestone_email'
      }))
    end

    def closed_merge_request_email(recipient_id, merge_request_id, updated_by_user_id, reason: nil, closed_via: nil)
      setup_merge_request_mail(merge_request_id, recipient_id)

      @updated_by = User.find(updated_by_user_id)
      mail_answer_thread(@merge_request, merge_request_thread_options(updated_by_user_id, reason))
    end

    def merged_merge_request_email(recipient_id, merge_request_id, updated_by_user_id, reason: nil, closed_via: nil)
      setup_merge_request_mail(merge_request_id, recipient_id)

      mail_answer_thread(@merge_request, merge_request_thread_options(updated_by_user_id, reason))
    end

    def request_review_merge_request_email(recipient_id, merge_request_id, updated_by_user_id, reason = nil)
      setup_merge_request_mail(merge_request_id, recipient_id)

      @updated_by = User.find(updated_by_user_id)
      mail_answer_thread(@merge_request, merge_request_thread_options(updated_by_user_id, reason))
    end

    def merge_request_status_email(recipient_id, merge_request_id, status, updated_by_user_id, reason = nil)
      setup_merge_request_mail(merge_request_id, recipient_id)

      @mr_status = status
      @updated_by = User.find(updated_by_user_id)
      mail_answer_thread(@merge_request, merge_request_thread_options(updated_by_user_id, reason))
    end

    def merge_request_unmergeable_email(recipient_id, merge_request_id, reason = nil)
      setup_merge_request_mail(merge_request_id, recipient_id)

      mail_answer_thread(@merge_request, merge_request_thread_options(@merge_request.author_id, reason))
    end

    def resolved_all_discussions_email(recipient_id, merge_request_id, resolved_by_user_id, reason = nil)
      setup_merge_request_mail(merge_request_id, recipient_id)

      @resolved_by = User.find(resolved_by_user_id)
      mail_answer_thread(@merge_request, merge_request_thread_options(resolved_by_user_id, reason))
    end

    def merge_when_pipeline_succeeds_email(recipient_id, merge_request_id, mwps_set_by_user_id, reason = nil)
      setup_merge_request_mail(merge_request_id, recipient_id)

      @mwps_set_by = ::User.find(mwps_set_by_user_id)
      mail_answer_thread(@merge_request, merge_request_thread_options(mwps_set_by_user_id, reason))
    end

    def merge_requests_csv_email(user, project, csv_data, export_status)
      @project = project
      @count = export_status.fetch(:rows_expected)
      @written_count = export_status.fetch(:rows_written)
      @truncated = export_status.fetch(:truncated)
      @size_limit = ActiveSupport::NumberHelper
        .number_to_human_size(ExportCsv::BaseService::TARGET_FILESIZE)

      filename = "#{project.full_path.parameterize}_merge_requests_#{Date.current.iso8601}.csv"
      attachments[filename] = { content: csv_data, mime_type: 'text/csv' }
      email_with_layout(
        to: user.notification_email_for(@project.group),
        subject: subject("Exported merge requests"))
    end

    def approved_merge_request_email(recipient_id, merge_request_id, approved_by_user_id, reason = nil)
      setup_merge_request_mail(merge_request_id, recipient_id)

      @approved_by = User.find(approved_by_user_id)
      mail_answer_thread(@merge_request, merge_request_thread_options(approved_by_user_id, reason))
    end

    def unapproved_merge_request_email(recipient_id, merge_request_id, unapproved_by_user_id, reason = nil)
      setup_merge_request_mail(merge_request_id, recipient_id)

      @unapproved_by = User.find(unapproved_by_user_id)
      mail_answer_thread(@merge_request, merge_request_thread_options(unapproved_by_user_id, reason))
    end

    private

    def setup_merge_request_mail(merge_request_id, recipient_id, present: false)
      @merge_request = MergeRequest.find(merge_request_id)
      @project = @merge_request.project
      @target_url = Gitlab::Routing.url_helpers.project_merge_request_url(@project, @merge_request)
      @recipient = User.find(recipient_id)

      @mr_presenter = @merge_request.present(current_user: @recipient) if present

      @sent_notification = SentNotification.record(@merge_request, recipient_id, reply_key)
    end

    def merge_request_thread_options(sender_id, reason = nil)
      {
        from: sender(sender_id),
        to: @recipient.notification_email_for(@project.group),
        subject: subject("#{@merge_request.title} (#{@merge_request.to_reference})"),
        'X-GitLab-NotificationReason' => reason
      }
    end
  end
end

Emails::MergeRequests.prepend_mod_with('Emails::MergeRequests')
