# frozen_string_literal: true

module UsersHelper
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

  def max_project_member_access(project)
    current_user&.max_member_access_for_project(project.id) || Gitlab::Access::NO_ACCESS
  end

  def max_project_member_access_cache_key(project)
    "access:#{max_project_member_access(project)}"
  end

  def user_status(user)
    return unless user

    unless user.association(:status).loaded?
      exception = RuntimeError.new("Status was not preloaded")
      Gitlab::Sentry.track_and_raise_for_dev_exception(exception, user: user.inspect)
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
      badges << { text: s_('AdminUsers|Blocked'), variant: 'danger' } if user.blocked?
      badges << { text: s_('AdminUsers|Admin'), variant: 'success' } if user.admin?
      badges << { text: s_('AdminUsers|External'), variant: 'secondary' } if user.external?
      badges << { text: s_("AdminUsers|It's you!"), variant: nil } if current_user == user
    end
  end

  private

  def get_profile_tabs
    tabs = []

    if can?(current_user, :read_user_profile, @user)
      tabs += [:overview, :activity, :groups, :contributed, :projects, :starred, :snippets]
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
end

UsersHelper.prepend_if_ee('EE::UsersHelper')
