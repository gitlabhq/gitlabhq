# frozen_string_literal: true

module UsersHelper
  def admin_users_data_attributes(users)
    {
      users: Admin::UserSerializer.new.represent(users, { current_user: current_user }).to_json,
      paths: admin_users_paths.to_json
    }
  end

  def user_link(user)
    link_to(user.name, user_path(user),
            title: user.email,
            class: 'has-tooltip commit-committer-link')
  end

  def user_email_help_text(user)
    return 'We also use email for avatar detection if no avatar is uploaded' unless user.unconfirmed_email.present?

    confirmation_link = link_to 'Resend confirmation e-mail', user_confirmation_path(user: { email: @user.unconfirmed_email }), method: :post

    h('Please click the link in the confirmation email before continuing. It was sent to ') +
      content_tag(:strong) { user.unconfirmed_email } + h('.') +
      content_tag(:p) { confirmation_link }
  end

  def profile_tabs
    @profile_tabs ||= get_profile_tabs
  end

  def profile_tab?(tab)
    profile_tabs.include?(tab)
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
  #
  # rubocop: disable CodeReuse/ActiveRecord: `projects` can be array which also responds to pluck
  def load_max_project_member_accesses(projects)
    current_user&.max_member_access_for_project_ids(projects.pluck(:id))
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def max_project_member_access(project)
    current_user&.max_member_access_for_project(project.id) || Gitlab::Access::NO_ACCESS
  end

  def max_project_member_access_cache_key(project)
    "access:#{max_project_member_access(project)}"
  end

  def show_status_emoji?(status)
    return false unless status

    status.message.present? || status.emoji != UserStatus::DEFAULT_EMOJI
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

  def user_badges_in_admin_section(user)
    [].tap do |badges|
      badges << blocked_user_badge(user) if user.blocked?
      badges << { text: s_('AdminUsers|Admin'), variant: 'success' } if user.admin?
      badges << { text: s_('AdminUsers|External'), variant: 'secondary' } if user.external?
      badges << { text: s_("AdminUsers|It's you!"), variant: 'muted' } if current_user == user
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

  def user_block_data(user, message)
    {
      path: block_admin_user_path(user),
      method: 'put',
      modal_attributes: {
        title: s_('AdminUsers|Block user %{username}?') % { username: sanitize_name(user.name) },
        messageHtml: message,
        okVariant: 'warning',
        okTitle: s_('AdminUsers|Block')
      }.to_json
    }
  end

  def user_unblock_data(user)
    {
      path: unblock_admin_user_path(user),
      method: 'put',
      modal_attributes: {
        title: s_('AdminUsers|Unblock user %{username}?') % { username: sanitize_name(user.name) },
        message: s_('AdminUsers|You can always block their account again if needed.'),
        okVariant: 'info',
        okTitle: s_('AdminUsers|Unblock')
      }.to_json
    }
  end

  def user_block_effects
    header = tag.p s_('AdminUsers|Blocking user has the following effects:')

    list = tag.ul do
      concat tag.li s_('AdminUsers|User will not be able to login')
      concat tag.li s_('AdminUsers|User will not be able to access git repositories')
      concat tag.li s_('AdminUsers|Personal projects will be left')
      concat tag.li s_('AdminUsers|Owned groups will be left')
    end

    header + list
  end

  def user_ban_data(user)
    {
      path: ban_admin_user_path(user),
      method: 'put',
      modal_attributes: {
        title: s_('AdminUsers|Ban user %{username}?') % { username: sanitize_name(user.name) },
        message: s_('AdminUsers|You can unban their account in the future. Their data remains intact.'),
        okVariant: 'warning',
        okTitle: s_('AdminUsers|Ban')
      }.to_json
    }
  end

  def user_unban_data(user)
    {
      path: unban_admin_user_path(user),
      method: 'put',
      modal_attributes: {
        title: s_('AdminUsers|Unban %{username}?') % { username: sanitize_name(user.name) },
        message: s_('AdminUsers|You ban their account in the future if necessary.'),
        okVariant: 'info',
        okTitle: s_('AdminUsers|Unban')
      }.to_json
    }
  end

  def user_ban_effects
    header = tag.p s_('AdminUsers|Banning the user has the following effects:')

    list = tag.ul do
      concat tag.li s_('AdminUsers|User will be blocked')
    end

    link_start = '<a href="%{url}" target="_blank">'.html_safe % { url: help_page_path("user/admin_area/moderate_users", anchor: "ban-a-user") }
    info = tag.p s_('AdminUsers|Learn more about %{link_start}banned users.%{link_end}').html_safe % { link_start: link_start, link_end: '</a>'.html_safe }

    header + list + info
  end

  def ban_feature_available?
    Feature.enabled?(:ban_user_feature_flag)
  end

  def user_deactivation_data(user, message)
    {
      path: deactivate_admin_user_path(user),
      method: 'put',
      modal_attributes: {
        title: s_('AdminUsers|Deactivate user %{username}?') % { username: sanitize_name(user.name) },
        messageHtml: message,
        okVariant: 'warning',
        okTitle: s_('AdminUsers|Deactivate')
      }.to_json
    }
  end

  def user_activation_data(user)
    {
      path: activate_admin_user_path(user),
      method: 'put',
      modal_attributes: {
        title: s_('AdminUsers|Activate user %{username}?') % { username: sanitize_name(user.name) },
        message: s_('AdminUsers|You can always deactivate their account again if needed.'),
        okVariant: 'info',
        okTitle: s_('AdminUsers|Activate')
      }.to_json
    }
  end

  def confirm_user_data(user)
    message = if user.unconfirmed_email.present?
                _('This user has an unconfirmed email address (%{email}). You may force a confirmation.') % { email: user.unconfirmed_email }
              else
                _('This user has an unconfirmed email address. You may force a confirmation.')
              end

    modal_attributes = Gitlab::Json.dump({
      title: s_('AdminUsers|Confirm user %{username}?') % { username: sanitize_name(user.name) },
      messageHtml: message,
      actionPrimary: {
        text: s_('AdminUsers|Confirm user'),
        attributes: [{ variant: 'info', 'data-qa-selector': 'confirm_user_confirm_button' }]
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
      qa_selector: 'confirm_user_button'
    }
  end

  def user_deactivation_effects
    header = tag.p s_('AdminUsers|Deactivating a user has the following effects:')

    list = tag.ul do
      concat tag.li s_('AdminUsers|The user will be logged out')
      concat tag.li s_('AdminUsers|The user will not be able to access git repositories')
      concat tag.li s_('AdminUsers|The user will not be able to access the API')
      concat tag.li s_('AdminUsers|The user will not receive any notifications')
      concat tag.li s_('AdminUsers|The user will not be able to use slash commands')
      concat tag.li s_('AdminUsers|When the user logs back in, their account will reactivate as a fully active account')
      concat tag.li s_('AdminUsers|Personal projects, group and user history will be left intact')
    end

    header + list
  end

  def user_display_name(user)
    return s_('UserProfile|Blocked user') if user.blocked?

    can_read_profile = can?(current_user, :read_user_profile, user)
    return s_('UserProfile|Unconfirmed user') unless user.confirmed? || can_read_profile

    user.name
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
      delete_with_contributions: admin_user_path(:id),
      admin_user: admin_user_path(:id),
      ban: ban_admin_user_path(:id),
      unban: unban_admin_user_path(:id)
    }
  end

  def blocked_user_badge(user)
    pending_approval_badge = { text: s_('AdminUsers|Pending approval'), variant: 'info' }
    return pending_approval_badge if user.blocked_pending_approval?

    banned_badge = { text: s_('AdminUsers|Banned'), variant: 'danger' }
    return banned_badge if user.banned?

    { text: s_('AdminUsers|Blocked'), variant: 'danger' }
  end

  def get_profile_tabs
    tabs = []

    if can?(current_user, :read_user_profile, @user)
      tabs += [:overview, :activity, :groups, :contributed, :projects, :starred, :snippets, :followers, :following]
    end

    tabs
  end

  def trials_link_url
    'https://about.gitlab.com/free-trial/'
  end

  def trials_allowed?(user)
    false
  end

  def get_current_user_menu_items
    items = []

    items << :sign_out if current_user

    return items if current_user&.required_terms_not_accepted?

    items << :help
    items << :profile if can?(current_user, :read_user, current_user)
    items << :settings if can?(current_user, :update_user, current_user)
    items << :start_trial if trials_allowed?(current_user)

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
    end

    html_escape(s_('Profile|%{job_title} at %{organization}')) % { job_title: job_title, organization: organization }
  end

  def user_table_headers
    [
      {
        section_class_name: 'section-40',
        header_text: _('Name')
      },
      {
        section_class_name: 'section-10',
        header_text: _('Projects')
      },
      {
        section_class_name: 'section-15',
        header_text: _('Created on')
      },
      {
        section_class_name: 'section-15',
        header_text: _('Last activity')
      }
    ]
  end
end

UsersHelper.prepend_mod_with('UsersHelper')
