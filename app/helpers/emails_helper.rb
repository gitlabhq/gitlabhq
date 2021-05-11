# frozen_string_literal: true

module EmailsHelper
  include AppearancesHelper

  # Google Actions
  # https://developers.google.com/gmail/markup/reference/go-to-action
  def email_action(url)
    name = action_title(url)
    if name
      data = {
        "@context" => "http://schema.org",
        "@type" => "EmailMessage",
        "action" => {
          "@type" => "ViewAction",
          "name" => name,
          "url" => url
          }
        }

      content_tag :script, type: 'application/ld+json' do
        data.to_json.html_safe
      end
    end
  end

  def action_title(url)
    return unless url

    %w(merge_requests issues commit).each do |action|
      if url.split("/").include?(action)
        return "View #{action.humanize.singularize}"
      end
    end

    nil
  end

  def sanitize_name(name)
    if name =~ URI::DEFAULT_PARSER.regexp[:URI_REF]
      name.tr('.', '_')
    else
      name
    end
  end

  def password_reset_token_valid_time
    valid_hours = Devise.reset_password_within / 60 / 60
    if valid_hours >= 24
      unit = 'day'
      valid_length = (valid_hours / 24).floor
    else
      unit = 'hour'
      valid_length = valid_hours.floor
    end

    pluralize(valid_length, unit)
  end

  def header_logo
    if current_appearance&.header_logo?
      image_tag(
        current_appearance.header_logo_path,
        style: 'height: 50px'
      )
    else
      image_tag(
        image_url('mailers/gitlab_header_logo.gif'),
        size: '55x50',
        alt: 'GitLab'
      )
    end
  end

  def email_default_heading(text)
    content_tag :h1, text, style: [
      "font-family:'Helvetica Neue',Helvetica,Arial,sans-serif",
      'color:#333333',
      'font-size:18px',
      'font-weight:400',
      'line-height:1.4',
      'padding:0',
      'margin:0',
      'text-align:center'
    ].join(';')
  end

  def closure_reason_text(closed_via, format: nil)
    case closed_via
    when MergeRequest
      merge_request = MergeRequest.find(closed_via[:id]).present

      return "" unless Ability.allowed?(@recipient, :read_merge_request, merge_request)

      case format
      when :html
        merge_request_link = link_to(merge_request.to_reference, merge_request.web_url)
        _("via merge request %{link}").html_safe % { link: merge_request_link }
      else
        # If it's not HTML nor text then assume it's text to be safe
        _("via merge request %{link}") % { link: "#{merge_request.to_reference} (#{merge_request.web_url})" }
      end
    when String
      # Technically speaking this should be Commit but per
      # https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/15610#note_163812339
      # we can't deserialize Commit without custom serializer for ActiveJob
      return "" unless Ability.allowed?(@recipient, :download_code, @project)

      _("via %{closed_via}") % { closed_via: closed_via }
    else
      ""
    end
  end

  # "You are receiving this email because #{reason} on #{gitlab_host}."
  def notification_reason_text(reason)
    gitlab_host = Gitlab.config.gitlab.host

    case reason
    when NotificationReason::OWN_ACTIVITY
      _("You're receiving this email because of your activity on %{host}.") % { host: gitlab_host }
    when NotificationReason::ASSIGNED
      _("You're receiving this email because you have been assigned an item on %{host}.") % { host: gitlab_host }
    when NotificationReason::MENTIONED
      _("You're receiving this email because you have been mentioned on %{host}.") % { host: gitlab_host }
    else
      _("You're receiving this email because of your account on %{host}.") % { host: gitlab_host }
    end
  end

  def create_list_id_string(project, list_id_max_length = 255)
    project_path_as_domain = project.full_path.downcase
      .split('/').reverse.join('/')
      .gsub(%r{[^a-z0-9\/]}, '-')
      .gsub(%r{\/+}, '.')
      .gsub(/(\A\.+|\.+\z)/, '')

    max_domain_length = list_id_max_length - Gitlab.config.gitlab.host.length - project.id.to_s.length - 2

    if max_domain_length < 3
      return project.id.to_s + "..." + Gitlab.config.gitlab.host
    end

    if project_path_as_domain.length > max_domain_length
      project_path_as_domain = project_path_as_domain.slice(0, max_domain_length)

      last_dot_index = project_path_as_domain[0..-2].rindex(".")
      last_dot_index ||= max_domain_length - 2

      project_path_as_domain = project_path_as_domain.slice(0, last_dot_index).concat("..")
    end

    project.id.to_s + "." + project_path_as_domain + "." + Gitlab.config.gitlab.host
  end

  def html_header_message
    return unless show_header?

    render_message(:header_message, style: '')
  end

  def html_footer_message
    return unless show_footer?

    render_message(:footer_message, style: '')
  end

  def text_header_message
    return unless show_header?

    strip_tags(render_message(:header_message, style: ''))
  end

  def text_footer_message
    return unless show_footer?

    strip_tags(render_message(:footer_message, style: ''))
  end

  def say_hi(user)
    _('Hi %{username}!') % { username: sanitize_name(user.name) }
  end

  def say_hello(user)
    _('Hello, %{username}!') % { username: sanitize_name(user.name) }
  end

  def two_factor_authentication_disabled_text
    _('Two-factor authentication has been disabled for your GitLab account.')
  end

  def re_enable_two_factor_authentication_text(format: nil)
    url = profile_two_factor_auth_url

    case format
    when :html
      settings_link_to = generate_link(_('two-factor authentication settings'), url).html_safe
      _("If you want to re-enable two-factor authentication, visit the %{settings_link_to} page.").html_safe % { settings_link_to: settings_link_to }
    else
      _('If you want to re-enable two-factor authentication, visit %{two_factor_link}') %
        { two_factor_link: url }
    end
  end

  def admin_changed_password_text(format: nil)
    url = Gitlab.config.gitlab.url

    case format
    when :html
      link_to = generate_link(url, url).html_safe
      _('An administrator changed the password for your GitLab account on %{link_to}.').html_safe % { link_to: link_to }
    else
      _('An administrator changed the password for your GitLab account on %{link_to}.') % { link_to: url }
    end
  end

  def group_membership_expiration_changed_text(member, group)
    if member.expires?
      days = (member.expires_at - Date.today).to_i
      days_formatted = pluralize(days, 'day')

      _('Your %{group} membership will now expire in %{days}.') % { group: group.human_name, days: days_formatted }
    else
      _('Your membership in %{group} no longer expires.') % { group: group.human_name }
    end
  end

  def group_membership_expiration_changed_link(member, group, format: nil)
    url = group_group_members_url(group, search: member.user.username)

    case format
    when :html
      link_to = generate_link('group membership', url).html_safe
      _('For additional information, review your %{link_to} or contact your group owner.').html_safe % { link_to: link_to }
    else
      _('For additional information, review your group membership: %{link_to} or contact your group owner.') % { link_to: url }
    end
  end

  def instance_access_request_text(user, format: nil)
    gitlab_host = Gitlab.config.gitlab.host

    _('%{username} has asked for a GitLab account on your instance %{host}:') % { username: sanitize_name(user.name), host: gitlab_host }
  end

  def instance_access_request_link(user, format: nil)
    url = admin_user_url(user)

    case format
    when :html
      user_page = '<a href="%{url}" target="_blank" rel="noopener noreferrer">'.html_safe % { url: url }
      _("Click %{link_start}here%{link_end} to view the request.").html_safe % { link_start: user_page, link_end: '</a>'.html_safe }
    else
      _('Click %{link_to} to view the request.') % { link_to: url }
    end
  end

  def contact_your_administrator_text
    _('Please contact your administrator with any questions.')
  end

  def change_reviewer_notification_text(new_reviewers, previous_reviewers, html_tag = nil)
    new = new_reviewers.any? ? users_to_sentence(new_reviewers) : s_('ChangeReviewer|Unassigned')
    old = previous_reviewers.any? ? users_to_sentence(previous_reviewers) : nil

    if html_tag.present?
      new = content_tag(html_tag, new)
      old = content_tag(html_tag, old) if old.present?
    end

    if old.present?
      s_('ChangeReviewer|Reviewer changed from %{old} to %{new}').html_safe % { old: old, new: new }
    else
      s_('ChangeReviewer|Reviewer changed to %{new}').html_safe % { new: new }
    end
  end

  private

  def users_to_sentence(users)
    sanitize_name(users.map(&:name).to_sentence)
  end

  def generate_link(text, url)
    link_to(text, url, target: :_blank, rel: 'noopener noreferrer')
  end

  def show_footer?
    email_header_and_footer_enabled? && current_appearance&.show_footer?
  end

  def show_header?
    email_header_and_footer_enabled? && current_appearance&.show_header?
  end

  def email_header_and_footer_enabled?
    current_appearance&.email_header_and_footer_enabled?
  end
end

EmailsHelper.prepend_mod_with('EmailsHelper')
