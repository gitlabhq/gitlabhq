module UsersHelper
  def user_link(user)
    link_to(user.name, user_path(user),
            title: user.email,
            class: 'has-tooltip commit-committer-link')
  end

  def user_email_help_text(user)
    return 'We also use email for avatar detection if no avatar is uploaded.' unless user.unconfirmed_email.present?

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

  private

  def get_profile_tabs
    [:activity, :groups, :contributed, :projects, :snippets]
  end
end
