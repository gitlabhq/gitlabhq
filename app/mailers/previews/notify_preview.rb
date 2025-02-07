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

  def new_user_email
    Notify.new_user_email(user.id).message
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

      create_note(
        noteable_type: 'merge_request',
        noteable_id: merge_request.id,
        type: 'DiffNote',
        position: position,
        note: note
      )
    end
  end

  def resource_access_token_about_to_expire_email
    Notify.bot_resource_access_token_about_to_expire_email(user, group, 'token_name')
  end

  def access_token_created_email
    Notify.access_token_created_email(user, 'token_name').message
  end

  def access_token_expired_email
    token_names = []
    Notify.access_token_expired_email(user, token_names).message
  end

  def access_token_revoked_email
    Notify.access_token_revoked_email(user, 'token_name').message
  end

  def access_token_about_to_expire_email
    Notify.access_token_about_to_expire_email(user, ['%w', '%w']).message
  end

  def ssh_key_expired_email
    fingerprints = []
    Notify.ssh_key_expired_email(user, fingerprints).message
  end

  def new_mention_in_merge_request_email
    Notify.new_mention_in_merge_request_email(user.id, merge_request.id, user.id).message
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

  def import_work_items_csv_email
    Notify.import_work_items_csv_email(user.id, project.id, { success: 4, error_lines: [2, 3, 4], parse_error: false })
  end

  def issues_csv_email
    Notify.issues_csv_email(
      user,
      project,
      '1997,Ford,E350',
      { truncated: false, rows_expected: 3, rows_written: 3 }
    ).message
  end

  def new_issue_email
    Notify.new_issue_email(user.id, issue.id).message
  end

  def new_merge_request_email
    Notify.new_merge_request_email(user.id, merge_request.id).message
  end

  def new_ssh_key_email
    cleanup do
      Notify.new_ssh_key_email(key.id).message
    end
  end

  def closed_merge_request_email
    Notify.closed_merge_request_email(user.id, merge_request.id, user.id).message
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

  def member_access_granted_email
    Notify.member_access_granted_email(member.source_type, member.id).message
  end

  def member_access_requested_email
    Notify.member_access_requested_email(member.source_type, member.id, user.id).message
  end

  def member_invite_accepted_email
    Notify.member_invite_accepted_email(member.source_type, member.id).message
  end

  def member_about_to_expire_email
    cleanup do
      member = project.add_member(user, Gitlab::Access::GUEST, expires_at: 7.days.from_now.to_date)
      Notify.member_about_to_expire_email('project', member.id).message
    end
  end

  def pages_domain_enabled_email
    cleanup do
      Notify.pages_domain_enabled_email(pages_domain, user).message
    end
  end

  def pages_domain_disabled_email
    cleanup do
      Notify.pages_domain_disabled_email(pages_domain, user).message
    end
  end

  def pages_domain_verification_succeeded_email
    cleanup do
      Notify.pages_domain_verification_succeeded_email(pages_domain, user).message
    end
  end

  def pages_domain_verification_failed_email
    cleanup do
      Notify.pages_domain_verification_failed_email(pages_domain, user).message
    end
  end

  def pages_domain_auto_ssl_failed_email
    cleanup do
      Notify.pages_domain_auto_ssl_failed_email(pages_domain, user).message
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
    Notify.unknown_sign_in_email(user, '127.0.0.1', Time.current, country: 'Germany', city: 'Frankfurt').message
  end

  def two_factor_otp_attempt_failed_email
    Notify.two_factor_otp_attempt_failed_email(user, '127.0.0.1').message
  end

  def disabled_two_factor_email
    Notify.disabled_two_factor_email(user).message
  end

  def new_email_address_added_email
    Notify.new_email_address_added_email(user, 'someone@gitlab.com').message
  end

  def service_desk_new_note_email
    ensure_support_bot_exists
    ensure_visual_review_bot_exists

    cleanup do
      note = create_note(noteable_type: 'Issue', noteable_id: issue.id, note: 'Issue note content')
      participant = IssueEmailParticipant.create!(issue: issue, email: 'user@example.com')

      Notify.service_desk_new_note_email(issue.id, note.id, participant).message
    end
  end

  def service_desk_thank_you_email
    Notify.service_desk_thank_you_email(issue.id).message
  end

  def service_desk_new_participant_email
    ensure_support_bot_exists

    cleanup do
      participant = IssueEmailParticipant.create!(issue: issue, email: 'user@example.com')

      Notify.service_desk_new_participant_email(issue.id, participant).message
    end
  end

  def service_desk_custom_email_verification_email
    ensure_support_bot_exists

    cleanup do
      setup_service_desk_custom_email_objects

      Notify.service_desk_custom_email_verification_email(service_desk_setting).message
    end
  end

  def service_desk_verification_triggered_email
    cleanup do
      setup_service_desk_custom_email_objects

      Notify.service_desk_verification_triggered_email(service_desk_setting, 'owner@example.com').message
    end
  end

  def service_desk_verification_result_email_for_verified_state
    cleanup do
      setup_service_desk_custom_email_objects

      custom_email_verification.mark_as_finished!

      Notify.service_desk_verification_result_email(service_desk_setting, 'owner@example.com').message
    end
  end

  def service_desk_verification_result_email_for_incorrect_forwarding_target_error
    service_desk_verification_result_email_for_error_state(error: :incorrect_forwarding_target)
  end

  def service_desk_verification_result_email_for_read_timeout_error
    service_desk_verification_result_email_for_error_state(error: :read_timeout)
  end

  def service_desk_verification_result_email_for_incorrect_token_error
    service_desk_verification_result_email_for_error_state(error: :incorrect_token)
  end

  def service_desk_verification_result_email_for_incorrect_from_error
    service_desk_verification_result_email_for_error_state(error: :incorrect_from)
  end

  def service_desk_verification_result_email_for_mail_not_received_within_timeframe_error
    service_desk_verification_result_email_for_error_state(error: :mail_not_received_within_timeframe)
  end

  def service_desk_verification_result_email_for_invalid_credentials_error
    service_desk_verification_result_email_for_error_state(error: :invalid_credentials)
  end

  def service_desk_verification_result_email_for_smtp_host_issue_error
    service_desk_verification_result_email_for_error_state(error: :smtp_host_issue)
  end

  def merge_when_pipeline_succeeds_email
    Notify.merge_when_pipeline_succeeds_email(user.id, merge_request.id, user.id).message
  end

  def inactive_project_deletion_warning
    Notify.inactive_project_deletion_warning_email(project, user, '2022-04-22').message
  end

  def verification_instructions_email
    Notify.verification_instructions_email(user.email, token: '123456').message
  end

  def project_was_exported_email
    Notify.project_was_exported_email(user, project).message
  end

  def repository_cleanup_success_email
    Notify.repository_cleanup_success_email(project, user).message
  end

  def request_review_merge_request_email
    Notify.request_review_merge_request_email(user.id, merge_request.id, user.id).message
  end

  def new_review_email
    review = Review.last
    mr_author = review.merge_request.author

    Notify.new_review_email(mr_author.id, review.id).message
  end

  def project_was_moved_email
    Notify.project_was_moved_email(project.id, user.id, "gitlab/gitlab").message
  end

  def github_gists_import_errors_email
    Notify.github_gists_import_errors_email(
      user.id,
      { '12345' => 'Snippet maximum file count exceeded', '67890' => 'error message 2' }
    ).message
  end

  def project_import_complete
    project_id = ProjectImportState.last.project_id
    project = Project.find(project_id)
    creator_id = project.creator_id

    Notify.project_import_complete(project_id, creator_id, true, project.safe_import_url(masked: false)).message
  end

  def bulk_import_complete
    bulk_import = BulkImport.last

    Notify.bulk_import_complete(user.id, bulk_import.id)
  end

  def bulk_import_csv_user_mapping_success
    Notify.bulk_import_csv_user_mapping(user.id, group.id, 94125, 0)
  end

  def bulk_import_csv_user_mapping_failed
    Notify.bulk_import_csv_user_mapping(user.id, group.id, 71249, 824)
  end

  def import_source_user_reassign
    source_user = Import::SourceUser.last

    Notify.import_source_user_reassign(source_user.id)
  end

  def import_source_user_rejected
    source_user = Import::SourceUser.last

    Notify.import_source_user_rejected(source_user.id)
  end

  def repository_rewrite_history_success_email
    Notify.repository_rewrite_history_success_email(project, user)
  end

  def repository_rewrite_history_failure_email
    Notify.repository_rewrite_history_failure_email(project, user, 'Error message')
  end

  private

  def project
    @project ||= Project.first
  end

  def service_desk_verification_result_email_for_error_state(error:)
    cleanup do
      setup_service_desk_custom_email_objects

      custom_email_verification.mark_as_failed!(error)

      Notify.service_desk_verification_result_email(service_desk_setting, 'owner@example.com').message
    end
  end

  def setup_service_desk_custom_email_objects
    # Call accessors to ensure objects have been created
    custom_email_credential
    custom_email_verification

    # Update associations in projects, because we access
    # custom_email_credential and custom_email_verification via project
    project.reset
  end

  def custom_email_verification
    @custom_email_verification ||= project.service_desk_custom_email_verification ||
      ServiceDesk::CustomEmailVerification.create!(
        project: project,
        token: 'XXXXXXXXXXXX',
        triggerer: user,
        triggered_at: Time.current,
        state: 'started'
      )
  end

  def custom_email_credential
    @custom_email_credential ||= project.service_desk_custom_email_credential ||
      ServiceDesk::CustomEmailCredential.create!(
        project: project,
        smtp_address: 'smtp.gmail.com', # Use gmail, because Gitlab::HTTP_V2::UrlBlocker resolves DNS
        smtp_port: 587,
        smtp_username: 'user@gmail.com',
        smtp_password: 'supersecret'
      )
  end

  def service_desk_setting
    @service_desk_setting ||= project.service_desk_setting || ServiceDeskSetting.create!(
      project: project,
      custom_email: 'user@gmail.com'
    )
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

  def group
    @group ||= Group.last
  end

  def member
    @member ||= Member.non_invite.non_request.last
  end

  def key
    @key ||= find_or_create_key
  end

  def find_or_create_key
    Key.last || Keys::CreateService.new(user).execute
  end

  def create_note(params)
    Notes::CreateService.new(project, user, params).execute
  end

  def note_email(method)
    ensure_visual_review_bot_exists
    # NOTE: This code path is only accessible in development mode so
    # using Gitlab::ExclusiveLease.skipping_transaction_check doesn't cause
    # production issues.
    Gitlab::ExclusiveLease.skipping_transaction_check do
      cleanup do
        note = yield

        Notify.public_send(method, user.id, note) # rubocop:disable GitlabSecurity/PublicSend
      end
    end
  end

  def ensure_support_bot_exists
    # If not called before cleanup creating support bot in app/mailers/emails/service_desk.rb
    # will obtain an exclusive lease.
    # The `cleanup` method wraps the email-generating-block in a transaction.
    # See issue: https://gitlab.com/gitlab-org/gitlab/-/issues/441523
    Users::Internal.support_bot
  end

  def ensure_visual_review_bot_exists
    # If not called before cleanup creating visual_review_bot in
    # app/services/notes/create_service.rb:191 will obtain an exclusive lease.
    # visual_review_bot is a EE only method.
    Users::Internal.try(:visual_review_bot)
  end

  def cleanup
    email = nil

    ApplicationRecord.transaction do
      email = yield
      raise ActiveRecord::Rollback
    end

    email
  end

  def pages_domain
    @pages_domain ||= PagesDomain.new(
      domain: 'my.example.com',
      project: project,
      verified_at: Time.now,
      enabled_until: 1.week.from_now
    )
  end
end

NotifyPreview.prepend_mod_with('Preview::NotifyPreview')
