# frozen_string_literal: true

module UsersHelper
  def admin_users_data_attributes(users)
    {
      users: Admin::UserSerializer.new.represent(users, { current_user: current_user }).to_json,
      paths: admin_users_paths.to_json
    }
  end

  def user_clear_status_at(user)
    # The user.status can be nil when the user has no status, so we need to protect against that case.
    # iso8601 is the official RFC supported format for frontend parsing of date:
    # https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Date/Date
    user.status&.clear_status_at&.to_fs(:iso8601)
  end

  def user_link(user)
    link_to(user.name, user_path(user), title: user.email, class: 'has-tooltip commit-committer-link')
  end

  def user_email_help_text(user)
    return _('We also use email for avatar detection if no avatar is uploaded.') unless user.unconfirmed_email.present?

    confirmation_link = link_to _('Resend confirmation e-mail'),
      user_confirmation_path(user: { email: user.unconfirmed_email }),
      method: :post
    (
      h(
        _('Please click the link in the confirmation email before continuing. It was sent to ' \
          '%{html_tag_strong_start}%{email}%{html_tag_strong_end}.')
      ) % {
        html_tag_strong_start: '<strong>'.html_safe,
        html_tag_strong_end: '</strong>'.html_safe,
        email: user.unconfirmed_email
      }
    ) + content_tag(:p) { confirmation_link }
  end

  def profile_actions(user)
    return [] unless can?(current_user, :read_user_profile, user)

    return [:overview, :activity] if user.bot?

    [:overview, :activity, :groups, :contributed, :projects, :starred, :snippets, :followers, :following]
  end

  def user_internal_regex_data
    settings = Gitlab::CurrentSettings.current_application_settings

    pattern, options = if settings.user_default_internal_regex_enabled?
                         regex = settings.user_default_internal_regex_instance
                         JsRegex.new(regex).to_h.slice(:source, :options).values
                       end

    { user_internal_regex_pattern: pattern, user_internal_regex_options: options }
  end

  def current_user_menu_items
    @current_user_menu_items ||= get_current_user_menu_items
  end

  def current_user_menu?(item)
    current_user_menu_items.include?(item)
  end

  # Used to preload when you are rendering many projects and checking access
  def load_max_project_member_accesses(projects)
    # There are two different request store paradigms for max member access and
    # we need to preload both of them. One is keyed User the other is keyed by
    # Project. See https://gitlab.com/gitlab-org/gitlab/-/issues/396822

    # rubocop: disable CodeReuse/ActiveRecord: `projects` can be array which also responds to pluck
    project_ids = projects.pluck(:id)
    # rubocop: enable CodeReuse/ActiveRecord

    preload_project_associations(projects)

    Preloaders::UserMaxAccessLevelInProjectsPreloader
      .new(project_ids, current_user)
      .execute

    current_user&.max_member_access_for_project_ids(project_ids)
  end

  def max_project_member_access(project)
    current_user&.max_member_access_for_project(project.id) || Gitlab::Access::NO_ACCESS
  end

  def user_status(user)
    return unless user

    unless user.association(:status).loaded?
      exception = RuntimeError.new("Status was not preloaded")
      Gitlab::ErrorTracking.track_and_raise_for_dev_exception(exception, user: user.inspect)
    end

    return unless user.status

    content_tag :span,
      class: 'user-status-emoji has-tooltip',
      title: user.status.message_html,
      data: { html: true, placement: 'top' } do
      emoji_icon user.status.emoji
    end
  end

  def impersonation_enabled?
    Gitlab.config.gitlab.impersonation_enabled
  end

  def impersonation_tokens_enabled?
    impersonation_enabled?
  end

  def can_impersonate_user(user, impersonation_in_progress)
    can?(user, :log_in) && !user.password_expired? && !impersonation_in_progress
  end

  def impersonation_error_text(user, impersonation_in_progress)
    if impersonation_in_progress
      _("You are already impersonating another user")
    elsif user.blocked?
      _("You cannot impersonate a blocked user")
    elsif user.password_expired?
      _("You cannot impersonate a user with an expired password")
    elsif user.internal?
      _("You cannot impersonate an internal user")
    else
      _("You cannot impersonate a user who cannot log in")
    end
  end

  def user_badges_in_admin_section(user)
    [].tap do |badges|
      badges << blocked_user_badge(user) if user.blocked?
      badges << { text: s_('AdminUsers|Admin'), variant: 'success' } if user.admin? # rubocop:disable Cop/UserAdmin
      badges << { text: s_('AdminUsers|Bot'), variant: 'muted' } if user.bot?
      badges << { text: s_('AdminUsers|Deactivated'), variant: 'danger' } if user.deactivated?
      badges << { text: s_('AdminUsers|External'), variant: 'secondary' } if user.external?
      badges << { text: s_("AdminUsers|It's you!"), variant: 'muted' } if current_user == user
      badges << { text: s_("AdminUsers|Locked"), variant: 'warning' } if user.access_locked?
    end
  end

  def work_information(user, with_schema_markup: false)
    return unless user

    organization = user.organization
    job_title = user.job_title

    if organization.present? && job_title.present?
      render_job_title_and_organization(job_title, organization, with_schema_markup: with_schema_markup)
    elsif job_title.present?
      render_job_title(job_title, with_schema_markup: with_schema_markup)
    elsif organization.present?
      render_organization(organization, with_schema_markup: with_schema_markup)
    end
  end

  def can_force_email_confirmation?(user)
    !user.confirmed?
  end

  def confirm_user_data(user)
    message = if user.unconfirmed_email.present?
                safe_format(
                  _('This user has an unconfirmed email address (%{email}). You may force a confirmation.'),
                  email: user.unconfirmed_email
                )
              else
                _('This user has an unconfirmed email address. You may force a confirmation.')
              end

    modal_attributes = Gitlab::Json.dump({
      title: s_('AdminUsers|Confirm user %{username}?') % { username: sanitize_name(user.name) },
      messageHtml: message,
      actionPrimary: {
        text: s_('AdminUsers|Confirm user'),
        attributes: [{ variant: 'confirm', 'data-testid': 'confirm-user-confirm-button' }]
      },
      actionSecondary: {
        text: _('Cancel'),
        attributes: [{ variant: 'default' }]
      }
    })

    {
      path: confirm_admin_user_path(user),
      method: 'put',
      modal_attributes: modal_attributes,
      testid: 'confirm-user-button'
    }
  end

  def user_display_name(user)
    return s_('UserProfile|Blocked user') if user.blocked?

    can_read_profile = can?(current_user, :read_user_profile, user)
    return s_('UserProfile|Unconfirmed user') unless user.confirmed? || can_read_profile

    user.name
  end

  def admin_user_actions_data_attributes(user)
    {
      user: Admin::UserEntity.represent(user, { current_user: current_user }).to_json,
      paths: admin_users_paths.to_json
    }
  end

  def has_contact_info?(user)
    contact_fields = %i[bluesky discord linkedin mastodon skype twitter website_url]
    has_contact = contact_fields.any? { |field| user.public_send(field).present? }  # rubocop:disable GitlabSecurity/PublicSend -- fields are controlled, it is safe.
    has_contact || display_public_email?(user)
  end

  def display_public_email?(user)
    user.public_email.present?
  end

  def user_profile_app_data(user)
    {
      followees_count: user.followees.count,
      followers_count: user.followers.count,
      user_calendar_path: user_calendar_path(user, :json),
      user_activity_path: user_activity_path(user, :json),
      utc_offset: local_timezone_instance(user.timezone).now.utc_offset,
      user_id: user.id,
      snippets_empty_state: image_path('illustrations/empty-state/empty-snippets-md.svg'),
      new_snippet_path: (new_snippet_path if can?(current_user, :create_snippet)),
      follow_empty_state: image_path('illustrations/empty-state/empty-friends-md.svg')
    }
  end

  def moderation_status(user)
    return unless user.present?

    if user.banned?
      _('Banned')
    elsif user.blocked?
      _('Blocked')
    else
      _('Active')
    end
  end

  def user_profile_actions_data(user)
    basic_actions_data = {
      user_id: user.id
    }

    if can?(current_user, :read_user_profile, user)
      basic_actions_data[:rss_subscription_path] = user_path(user, rss_url_options)
    end

    return basic_actions_data if !current_user || current_user == user

    basic_actions_data.merge(
      report_abuse_path: add_category_abuse_reports_path,
      reported_user_id: user.id,
      reported_from_url: user_url(user)
    )
  end

  def email_verification_token_expired?(email_sent_at:)
    return false unless email_sent_at

    token_valid_for = Users::EmailVerification::ValidateTokenService::TOKEN_VALID_FOR_MINUTES.minutes
    (email_sent_at + token_valid_for).before?(Time.zone.now)
  end

  private

  def admin_users_paths
    {
      edit: edit_admin_user_path(:id),
      approve: approve_admin_user_path(:id),
      reject: reject_admin_user_path(:id),
      unblock: unblock_admin_user_path(:id),
      block: block_admin_user_path(:id),
      deactivate: deactivate_admin_user_path(:id),
      activate: activate_admin_user_path(:id),
      unlock: unlock_admin_user_path(:id),
      delete: admin_user_path(:id),
      delete_with_contributions: admin_user_path(:id, hard_delete: true),
      admin_user: admin_user_path(:id),
      ban: ban_admin_user_path(:id),
      unban: unban_admin_user_path(:id),
      trust: trust_admin_user_path(:id),
      untrust: untrust_admin_user_path(:id)
    }
  end

  def blocked_user_badge(user)
    pending_approval_badge = { text: s_('AdminUsers|Pending approval'), variant: 'info' }
    return pending_approval_badge if user.blocked_pending_approval?

    banned_badge = { text: s_('AdminUsers|Banned'), variant: 'danger' }
    return banned_badge if user.banned?

    ldap_blocked_badge = { text: s_('AdminUsers|LDAP Blocked'), variant: 'danger' }
    return ldap_blocked_badge if user.ldap_blocked?

    { text: s_('AdminUsers|Blocked'), variant: 'danger' }
  end

  def get_current_user_menu_items
    items = []

    items << :sign_out if current_user

    return items if current_user&.required_terms_not_accepted?

    items << :help
    items << :profile if can?(current_user, :read_user, current_user)
    items << :settings if can?(current_user, :update_user, current_user)

    items
  end

  def render_job_title(job_title, with_schema_markup: false)
    if with_schema_markup
      content_tag :span, itemprop: 'jobTitle' do
        job_title
      end
    else
      job_title
    end
  end

  def render_organization(organization, with_schema_markup: false)
    if with_schema_markup
      content_tag :span, itemprop: 'worksFor' do
        organization
      end
    else
      organization
    end
  end

  def render_job_title_and_organization(job_title, organization, with_schema_markup: false)
    if with_schema_markup
      job_title = '<span itemprop="jobTitle">'.html_safe + job_title + "</span>".html_safe
      organization = '<span itemprop="worksFor">'.html_safe + organization + "</span>".html_safe

      ERB::Util.html_escape(
        s_('Profile|%{job_title} at %{organization}')
      ) % { job_title: job_title, organization: organization }
    else
      s_('Profile|%{job_title} at %{organization}') % { job_title: job_title, organization: organization }
    end
  end

  def preload_project_associations(_)
    # Overridden in EE
  end
end

UsersHelper.prepend_mod_with('UsersHelper')
