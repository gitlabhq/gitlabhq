# frozen_string_literal: true

class NotifyPreview < ActionMailer::Preview
  def note_merge_request_email_for_individual_note
    note_email(:note_merge_request_email) do
      note = <<-MD.strip_heredoc
        This is an individual note on a merge request :smiley:

        In this notification email, we expect to see:

        - The note contents (that's what you're looking at)
        - A link to view this note on GitLab
        - An explanation for why the user is receiving this notification
      MD

      create_note(noteable_type: 'merge_request', noteable_id: merge_request.id, note: note)
    end
  end

  def note_merge_request_email_for_discussion
    note_email(:note_merge_request_email) do
      note = <<-MD.strip_heredoc
        This is a new discussion on a merge request :smiley:

        In this notification email, we expect to see:

        - A line saying who started this discussion
        - The note contents (that's what you're looking at)
        - A link to view this discussion on GitLab
        - An explanation for why the user is receiving this notification
      MD

      create_note(noteable_type: 'merge_request', noteable_id: merge_request.id, type: 'DiscussionNote', note: note)
    end
  end

  def note_merge_request_email_for_diff_discussion
    note_email(:note_merge_request_email) do
      note = <<-MD.strip_heredoc
        This is a new discussion on a merge request :smiley:

        In this notification email, we expect to see:

        - A line saying who started this discussion and on what file
        - The diff
        - The note contents (that's what you're looking at)
        - A link to view this discussion on GitLab
        - An explanation for why the user is receiving this notification
      MD

      position = Gitlab::Diff::Position.new(
        old_path: "files/ruby/popen.rb",
        new_path: "files/ruby/popen.rb",
        old_line: nil,
        new_line: 14,
        diff_refs: merge_request.diff_refs
      )

      create_note(noteable_type: 'merge_request', noteable_id: merge_request.id, type: 'DiffNote', position: position, note: note)
    end
  end

  def new_mention_in_merge_request_email
    Notify.new_mention_in_merge_request_email(user.id, issue.id, user.id).message
  end

  def closed_issue_email
    Notify.closed_issue_email(user.id, issue.id, user.id).message
  end

  def issue_status_changed_email
    Notify.issue_status_changed_email(user.id, issue.id, 'closed', user.id).message
  end

  def removed_milestone_issue_email
    Notify.removed_milestone_issue_email(user.id, issue.id, user.id)
  end

  def changed_milestone_issue_email
    Notify.changed_milestone_issue_email(user.id, issue.id, milestone, user.id)
  end

  def import_issues_csv_email
    Notify.import_issues_csv_email(user.id, project.id, { success: 3, errors: [5, 6, 7], valid_file: true })
  end

  def issues_csv_email
    Notify.issues_csv_email(user, project, '1997,Ford,E350', { truncated: false, rows_expected: 3, rows_written: 3 }).message
  end

  def new_issue_email
    Notify.new_issue_email(user.id, issue.id).message
  end

  def new_merge_request_email
    Notify.new_merge_request_email(user.id, merge_request.id).message
  end

  def closed_merge_request_email
    Notify.closed_merge_request_email(user.id, issue.id, user.id).message
  end

  def merge_request_status_email
    Notify.merge_request_status_email(user.id, merge_request.id, 'reopened', user.id).message
  end

  def merge_request_unmergeable_email
    Notify.merge_request_unmergeable_email(user.id, merge_request.id, 'conflict').message
  end

  def merged_merge_request_email
    Notify.merged_merge_request_email(user.id, merge_request.id, user.id).message
  end

  def removed_milestone_merge_request_email
    Notify.removed_milestone_merge_request_email(user.id, merge_request.id, user.id)
  end

  def changed_milestone_merge_request_email
    Notify.changed_milestone_merge_request_email(user.id, merge_request.id, milestone, user.id)
  end

  def member_access_denied_email
    Notify.member_access_denied_email('project', project.id, user.id).message
  end

  def member_access_granted_email
    Notify.member_access_granted_email(member.source_type, member.id).message
  end

  def member_access_requested_email
    Notify.member_access_requested_email(member.source_type, member.id, user.id).message
  end

  def member_invite_accepted_email
    Notify.member_invite_accepted_email(member.source_type, member.id).message
  end

  def member_invite_declined_email
    Notify.member_invite_declined_email(
      'project',
      project.id,
      'invite@example.com',
      user.id
    ).message
  end

  def member_invited_email
    Notify.member_invited_email('project', member.id, '1234').message
  end

  def pages_domain_enabled_email
    cleanup do
      pages_domain = PagesDomain.new(domain: 'my.example.com', project: project, verified_at: Time.now, enabled_until: 1.week.from_now)

      Notify.pages_domain_enabled_email(pages_domain, user).message
    end
  end

  def pipeline_success_email
    Notify.pipeline_success_email(pipeline, pipeline.user.try(:email))
  end

  def pipeline_failed_email
    Notify.pipeline_failed_email(pipeline, pipeline.user.try(:email))
  end

  def pipeline_fixed_email
    Notify.pipeline_fixed_email(pipeline, pipeline.user.try(:email))
  end

  def autodevops_disabled_email
    Notify.autodevops_disabled_email(pipeline, user.email).message
  end

  def remote_mirror_update_failed_email
    Notify.remote_mirror_update_failed_email(remote_mirror.id, user.id).message
  end

  def unknown_sign_in_email
    Notify.unknown_sign_in_email(user, '127.0.0.1', Time.current).message
  end

  def service_desk_new_note_email
    cleanup do
      note = create_note(noteable_type: 'Issue', noteable_id: issue.id, note: 'Issue note content')

      Notify.service_desk_new_note_email(issue.id, note.id, 'someone@gitlab.com').message
    end
  end

  def service_desk_thank_you_email
    Notify.service_desk_thank_you_email(issue.id).message
  end

  def merge_when_pipeline_succeeds_email
    Notify.merge_when_pipeline_succeeds_email(user.id, merge_request.id, user.id).message
  end

  private

  def project
    @project ||= Project.find_by_full_path('gitlab-org/gitlab-test')
  end

  def issue
    @issue ||= project.issues.first
  end

  def merge_request
    @merge_request ||= project.merge_requests.first
  end

  def milestone
    @milestone ||= issue.milestone
  end

  def pipeline
    @pipeline = Ci::Pipeline.last
  end

  def remote_mirror
    @remote_mirror ||= RemoteMirror.last
  end

  def user
    @user ||= User.last
  end

  def member
    @member ||= Member.last
  end

  def create_note(params)
    Notes::CreateService.new(project, user, params).execute
  end

  def note_email(method)
    cleanup do
      note = yield

      Notify.public_send(method, user.id, note) # rubocop:disable GitlabSecurity/PublicSend
    end
  end

  def cleanup
    email = nil

    ActiveRecord::Base.transaction do # rubocop: disable Database/MultipleDatabases
      email = yield
      raise ActiveRecord::Rollback
    end

    email
  end
end

NotifyPreview.prepend_mod_with('Preview::NotifyPreview')
