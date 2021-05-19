# frozen_string_literal: true

module Emails
  module Issues
    def new_issue_email(recipient_id, issue_id, reason = nil)
      setup_issue_mail(issue_id, recipient_id)

      mail_new_thread(@issue, issue_thread_options(@issue.author_id, recipient_id, reason))
    end

    def issue_due_email(recipient_id, issue_id, reason = nil)
      setup_issue_mail(issue_id, recipient_id)

      mail_answer_thread(@issue, issue_thread_options(@issue.author_id, recipient_id, reason))
    end

    def new_mention_in_issue_email(recipient_id, issue_id, updated_by_user_id, reason = nil)
      setup_issue_mail(issue_id, recipient_id)
      mail_answer_thread(@issue, issue_thread_options(updated_by_user_id, recipient_id, reason))
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def reassigned_issue_email(recipient_id, issue_id, previous_assignee_ids, updated_by_user_id, reason = nil)
      setup_issue_mail(issue_id, recipient_id)

      @previous_assignees = []
      @previous_assignees = User.where(id: previous_assignee_ids) if previous_assignee_ids.any?

      mail_answer_thread(@issue, issue_thread_options(updated_by_user_id, recipient_id, reason))
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def closed_issue_email(recipient_id, issue_id, updated_by_user_id, reason: nil, closed_via: nil)
      setup_issue_mail(issue_id, recipient_id, closed_via: closed_via)

      @updated_by = User.find(updated_by_user_id)
      @recipient = User.find(recipient_id)

      mail_answer_thread(@issue, issue_thread_options(updated_by_user_id, recipient_id, reason))
    end

    def relabeled_issue_email(recipient_id, issue_id, label_names, updated_by_user_id, reason = nil)
      setup_issue_mail(issue_id, recipient_id)

      @label_names = label_names
      @labels_url = project_labels_url(@project)
      mail_answer_thread(@issue, issue_thread_options(updated_by_user_id, recipient_id, reason))
    end

    def removed_milestone_issue_email(recipient_id, issue_id, updated_by_user_id, reason = nil)
      setup_issue_mail(issue_id, recipient_id)

      mail_answer_thread(@issue, issue_thread_options(updated_by_user_id, recipient_id, reason))
    end

    def changed_milestone_issue_email(recipient_id, issue_id, milestone, updated_by_user_id, reason = nil)
      setup_issue_mail(issue_id, recipient_id)

      @milestone = milestone
      @milestone_url = milestone_url(@milestone)
      mail_answer_thread(@issue, issue_thread_options(updated_by_user_id, recipient_id, reason).merge({
        template_name: 'changed_milestone_email'
      }))
    end

    def issue_status_changed_email(recipient_id, issue_id, status, updated_by_user_id, reason = nil)
      setup_issue_mail(issue_id, recipient_id)

      @issue_status = status
      @updated_by = User.find(updated_by_user_id)
      mail_answer_thread(@issue, issue_thread_options(updated_by_user_id, recipient_id, reason))
    end

    def issue_moved_email(recipient, issue, new_issue, updated_by_user, reason = nil)
      setup_issue_mail(issue.id, recipient.id)

      @new_issue = new_issue
      @new_project = new_issue.project
      @can_access_project = recipient.can?(:read_project, @new_project)
      mail_answer_thread(issue, issue_thread_options(updated_by_user.id, recipient.id, reason))
    end

    def issue_cloned_email(recipient, issue, new_issue, updated_by_user, reason = nil)
      setup_issue_mail(issue.id, recipient.id)

      @author = updated_by_user
      @issue = issue
      @new_issue = new_issue
      @can_access_project = recipient.can?(:read_project, @new_issue.project)
      mail_answer_thread(issue, issue_thread_options(updated_by_user.id, recipient.id, reason))
    end

    def import_issues_csv_email(user_id, project_id, results)
      @user = User.find(user_id)
      @project = Project.find(project_id)
      @results = results

      mail(to: @user.notification_email_for(@project.group), subject: subject('Imported issues')) do |format|
        format.html { render layout: 'mailer' }
        format.text { render layout: 'mailer' }
      end
    end

    def issues_csv_email(user, project, csv_data, export_status)
      @project = project
      @count = export_status.fetch(:rows_expected)
      @written_count = export_status.fetch(:rows_written)
      @truncated = export_status.fetch(:truncated)
      @size_limit = ActiveSupport::NumberHelper
        .number_to_human_size(Issuable::ExportCsv::BaseService::TARGET_FILESIZE)

      filename = "#{project.full_path.parameterize}_issues_#{Date.today.iso8601}.csv"
      attachments[filename] = { content: csv_data, mime_type: 'text/csv' }
      mail(to: user.notification_email_for(@project.group), subject: subject("Exported issues")) do |format|
        format.html { render layout: 'mailer' }
        format.text { render layout: 'mailer' }
      end
    end

    private

    def setup_issue_mail(issue_id, recipient_id, closed_via: nil)
      @issue = Issue.find(issue_id)
      @project = @issue.project
      @target_url = project_issue_url(@project, @issue)
      @closed_via = closed_via

      @sent_notification = SentNotification.record(@issue, recipient_id, reply_key)
    end

    def issue_thread_options(sender_id, recipient_id, reason)
      {
        from: sender(sender_id),
        to: User.find(recipient_id).notification_email_for(@project.group),
        subject: subject("#{@issue.title} (##{@issue.iid})"),
        'X-GitLab-NotificationReason' => reason
      }
    end
  end
end

Emails::Issues.prepend_mod_with('Emails::Issues')
