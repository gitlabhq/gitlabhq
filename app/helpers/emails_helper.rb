# frozen_string_literal: true

module EmailsHelper
  include AppearancesHelper
  include SafeFormatHelper

  def subject_with_suffix(subject_line)
    subject_line << Gitlab.config.gitlab.email_subject_suffix if Gitlab.config.gitlab.email_subject_suffix.present?

    subject_line.join(' | ')
  end

  module_function :subject_with_suffix

  # Google Actions
  # https://developers.google.com/gmail/markup/reference/go-to-action
  def email_action(url)
    name = action_title(url)
    return unless name

    gmail_goto_action(name, url)
  end

  def action_title(url)
    return unless url

    %w[merge_requests issues work_items commit].each do |action|
      return "View #{action.humanize.singularize}" if url.split("/").include?(action)
    end

    nil
  end

  def gmail_goto_action(name, url)
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

  def sanitize_name(name)
    if URI::DEFAULT_PARSER.regexp[:URI_REF].match?(name)
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
    if current_appearance&.header_logo? && !current_appearance.header_logo.filename.ends_with?('.svg')
      image_tag(
        current_appearance.header_logo_path,
        style: 'height: 50px'
      )
    else
      image_tag(
        image_url('mailers/gitlab_logo.png'),
        size: '55x55',
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

  def closure_reason_text(closed_via, format:, name:)
    name = sanitize_name(name)

    case closed_via
    when MergeRequest
      merge_request = MergeRequest.find(closed_via[:id]).present

      return "" unless Ability.allowed?(@recipient, :read_merge_request, merge_request)

      case format
      when :html
        merge_request_link = link_to(merge_request.to_reference, merge_request.web_url)
        safe_format(_("Issue was closed by %{name} with merge request %{link}"), name: name, link: merge_request_link)
      else
        # If it's not HTML nor text then assume it's text to be safe
        _("Issue was closed by %{name} with merge request %{link}") % {
          name: name,
          link: "#{merge_request.to_reference} (#{merge_request.web_url})"
        }
      end
    when String
      # Technically speaking this should be Commit but per
      # https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/15610#note_163812339
      # we can't deserialize Commit without custom serializer for ActiveJob
      return "" unless Ability.allowed?(@recipient, :download_code, @project)

      _("Issue was closed by %{name} with %{closed_via}") % { name: name, closed_via: closed_via }
    else
      type = work_item_type_for(@issue).capitalize

      if name
        _("%{type} was closed by %{name}") % { name: name, type: type }
      else
        ""
      end
    end
  end

  # "You are receiving this email because ... on #{host}. ..."
  def notification_reason_text(
    reason: nil,
    show_manage_notifications_link: false,
    show_help_link: false,
    manage_label_subscriptions_url: nil,
    unsubscribe_url: nil,
    format: :text
  )
    if unsubscribe_url && show_manage_notifications_link && show_help_link
      notification_reason_text_with_unsubscribe_and_manage_notifications_and_help_links(
        reason: reason,
        unsubscribe_url: unsubscribe_url,
        format: format
      )
    elsif !reason && manage_label_subscriptions_url && show_help_link
      notification_reason_text_with_manage_label_subscriptions_and_help_links(
        manage_label_subscriptions_url: manage_label_subscriptions_url,
        format: format
      )
    elsif show_manage_notifications_link && show_help_link
      notification_reason_text_with_manage_notifications_and_help_links(reason: reason, format: format)
    else
      notification_reason_text_without_links(reason: reason, format: format)
    end
  end

  def create_list_id_string(project, list_id_max_length = 255)
    project_path_as_domain = project.full_path.downcase
      .split('/').reverse.join('/')
      .gsub(%r{[^a-z0-9\/]}, '-')
      .gsub(%r{\/+}, '.')
      .gsub(/(\A\.+|\.+\z)/, '')

    max_domain_length = list_id_max_length - Gitlab.config.gitlab.host.length - project.id.to_s.length - 2

    return "#{project.id}...#{Gitlab.config.gitlab.host}" if max_domain_length < 3

    if project_path_as_domain.length > max_domain_length
      project_path_as_domain = project_path_as_domain.slice(0, max_domain_length)

      last_dot_index = project_path_as_domain[0..-2].rindex(".")
      last_dot_index ||= max_domain_length - 2

      project_path_as_domain = project_path_as_domain.slice(0, last_dot_index).concat("..")
    end

    "#{project.id}.#{project_path_as_domain}.#{Gitlab.config.gitlab.host}"
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

  def service_desk_email_additional_text
    # overridden on EE
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
      _("If you want to re-enable two-factor authentication, visit the %{settings_link_to} page.").html_safe % {
        settings_link_to: settings_link_to
      }
    else
      _('If you want to re-enable two-factor authentication, visit %{two_factor_link}') % {
        two_factor_link: url
      }
    end
  end

  def new_email_address_added_text(email)
    _('A new email address has been added to your GitLab account: %{email}') % { email: email }
  end

  def remove_email_address_text(format: nil)
    url = profile_emails_url

    case format
    when :html
      settings_link_to = generate_link(_('email address settings'), url).html_safe
      _("If you want to remove this email address, visit the %{settings_link_to} page.").html_safe % {
        settings_link_to: settings_link_to
      }
    else
      _('If you want to remove this email address, visit %{profile_link}') %
        { profile_link: url }
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

  def member_about_to_expire_text(member_source, days_to_expire, format: nil)
    days_formatted = pluralize(days_to_expire, 'day')

    case member_source
    when Project
      url = project_url(member_source)
    when Group
      url = group_url(member_source)
    end

    case format
    when :html
      link_to = generate_link(member_source.human_name, url).html_safe
      safe_format(
        _("Your membership in %{link_to} %{project_or_group_name} will expire in %{days_formatted}."),
        link_to: link_to,
        project_or_group_name: member_source.model_name.singular,
        days_formatted: days_formatted
      )
    else
      _("Your membership in %{project_or_group} %{project_or_group_name} will expire in %{days_formatted}.") % {
        project_or_group: member_source.human_name,
        project_or_group_name: member_source.model_name.singular,
        days_formatted: days_formatted
      }
    end
  end

  def member_about_to_expire_link(member, member_source, format: nil)
    project_or_group = member_source.human_name

    case member_source
    when Project
      url = project_project_members_url(member_source, search: member.user.username)
    when Group
      url = group_group_members_url(member_source, search: member.user.username)
    end

    case format
    when :html
      link_to = generate_link("#{member_source.class.name.downcase} membership", url).html_safe
      safe_format(
        _('For additional information, review your %{link_to} or contact your %{project_or_group} owner.'),
        link_to: link_to,
        project_or_group: project_or_group
      )
    else
      _('For additional information, review your %{project_or_group} membership: %{url} or contact your ' \
        '%{project_or_group} owner.') % {
          project_or_group: project_or_group,
          url: url
        }
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
      _('For additional information, review your %{link_to} or contact your group owner.').html_safe % {
        link_to: link_to
      }
    else
      _('For additional information, review your group membership: %{link_to} or contact your group owner.') % {
        link_to: url
      }
    end
  end

  def instance_access_request_text(user, format: nil)
    _('%{username} has asked for a GitLab account on your instance %{host}:').html_safe % {
      username: sanitize_name(user.name),
      host: gitlab_host_link(format)
    }
  end

  def instance_access_request_link(user, format: nil)
    url = admin_user_url(user)

    case format
    when :html
      user_page = '<a href="%{url}" target="_blank" rel="noopener noreferrer">'.html_safe % { url: url }
      _("Click %{link_start}here%{link_end} to view the request.").html_safe % {
        link_start: user_page,
        link_end: '</a>'.html_safe
      }
    else
      _('Click %{link_to} to view the request.') % { link_to: url }
    end
  end

  def link_start(url)
    '<a href="%{url}" target="_blank" rel="noopener noreferrer">'.html_safe % { url: url }
  end

  def link_end
    '</a>'.html_safe
  end

  def contact_your_administrator_text
    _('Please contact your administrator with any questions.')
  end

  def change_reviewer_notification_text(new_reviewers, previous_reviewers, html_tag = nil)
    if new_reviewers.empty?
      s_('ChangeReviewer|All reviewers were removed.')
    else
      added_reviewers = new_reviewers - previous_reviewers
      removed_reviewers = previous_reviewers - new_reviewers

      added_reviewers_text = if added_reviewers.any?
                               n_(
                                 '%{reviewer_names} was added as a reviewer.',
                                 '%{reviewer_names} were added as reviewers.',
                                 added_reviewers.size) % {
                                   reviewer_names: format_reviewers_string(added_reviewers, html_tag)
                                 }
                             end

      removed_reviewers_text = if removed_reviewers.any?
                                 n_(
                                   '%{reviewer_names} was removed from reviewers.',
                                   '%{reviewer_names} were removed from reviewers.',
                                   removed_reviewers.size) % {
                                     reviewer_names: format_reviewers_string(removed_reviewers, html_tag)
                                   }
                               end

      line_delimiter = html_tag.present? ? '<br>' : "\n"

      [added_reviewers_text, removed_reviewers_text].compact.join(line_delimiter).html_safe
    end
  end

  private

  def format_reviewers_string(reviewers, html_tag = nil)
    return unless reviewers.any?

    formatted_reviewers = users_to_sentence(reviewers)

    if html_tag.present?
      content_tag(html_tag, formatted_reviewers)
    else
      formatted_reviewers
    end
  end

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

  def gitlab_host_link(format)
    case format
    when :html
      generate_link(Gitlab.config.gitlab.host, Gitlab.config.gitlab.url)
    when :text
      Gitlab.config.gitlab.host
    end
  end

  def notification_reason_text_with_unsubscribe_and_manage_notifications_and_help_links(
    reason:,
    unsubscribe_url:,
    format:
  )
    unsubscribe_link_start = '<a href="%{url}" target="_blank" rel="noopener noreferrer">'.html_safe % {
      url: unsubscribe_url
    }
    unsubscribe_link_end = '</a>'.html_safe

    manage_notifications_link_start =
      '<a href="%{url}" target="_blank" rel="noopener noreferrer" class="mng-notif-link">'.html_safe % {
        url: profile_notifications_url
      }
    manage_notifications_link_end = '</a>'.html_safe

    help_link_start = '<a href="%{url}" target="_blank" rel="noopener noreferrer" class="help-link">'.html_safe % {
      url: help_url
    }
    help_link_end = '</a>'.html_safe

    case reason
    when NotificationReason::OWN_ACTIVITY
      _(
        "You're receiving this email because of your activity on %{host}. " \
          "%{unsubscribe_link_start}Unsubscribe%{unsubscribe_link_end} from this thread &middot; " \
          "%{manage_notifications_link_start}Manage all notifications%{manage_notifications_link_end} &middot; " \
          "%{help_link_start}Help%{help_link_end}"
      ).html_safe % {
        host: gitlab_host_link(format),
        unsubscribe_link_start: unsubscribe_link_start,
        unsubscribe_link_end: unsubscribe_link_end,
        manage_notifications_link_start: manage_notifications_link_start,
        manage_notifications_link_end: manage_notifications_link_end,
        help_link_start: help_link_start,
        help_link_end: help_link_end
      }
    when NotificationReason::ASSIGNED
      _(
        "You're receiving this email because you have been assigned an item on %{host}. " \
          "%{unsubscribe_link_start}Unsubscribe%{unsubscribe_link_end} from this thread &middot; " \
          "%{manage_notifications_link_start}Manage all notifications%{manage_notifications_link_end} &middot; " \
          "%{help_link_start}Help%{help_link_end}"
      ).html_safe % {
        host: gitlab_host_link(format),
        unsubscribe_link_start: unsubscribe_link_start,
        unsubscribe_link_end: unsubscribe_link_end,
        manage_notifications_link_start: manage_notifications_link_start,
        manage_notifications_link_end: manage_notifications_link_end,
        help_link_start: help_link_start,
        help_link_end: help_link_end
      }
    when NotificationReason::MENTIONED
      _(
        "You're receiving this email because you have been mentioned on %{host}. " \
          "%{unsubscribe_link_start}Unsubscribe%{unsubscribe_link_end} from this thread &middot; " \
          "%{manage_notifications_link_start}Manage all notifications%{manage_notifications_link_end} &middot; " \
          "%{help_link_start}Help%{help_link_end}"
      ).html_safe % {
        host: gitlab_host_link(format),
        unsubscribe_link_start: unsubscribe_link_start,
        unsubscribe_link_end: unsubscribe_link_end,
        manage_notifications_link_start: manage_notifications_link_start,
        manage_notifications_link_end: manage_notifications_link_end,
        help_link_start: help_link_start,
        help_link_end: help_link_end
      }
    else
      _(
        "You're receiving this email because of your account on %{host}. " \
          "%{unsubscribe_link_start}Unsubscribe%{unsubscribe_link_end} from this thread &middot; " \
          "%{manage_notifications_link_start}Manage all notifications%{manage_notifications_link_end} &middot; " \
          "%{help_link_start}Help%{help_link_end}"
      ).html_safe % {
        host: gitlab_host_link(format),
        unsubscribe_link_start: unsubscribe_link_start,
        unsubscribe_link_end: unsubscribe_link_end,
        manage_notifications_link_start: manage_notifications_link_start,
        manage_notifications_link_end: manage_notifications_link_end,
        help_link_start: help_link_start,
        help_link_end: help_link_end
      }
    end
  end

  def notification_reason_text_with_manage_label_subscriptions_and_help_links(manage_label_subscriptions_url:, format:)
    manage_label_subscriptions_link_start =
      '<a href="%{url}" target="_blank" rel="noopener noreferrer" class="mng-notif-link">'.html_safe % {
        url: manage_label_subscriptions_url
      }
    manage_label_subscriptions_link_end = '</a>'.html_safe

    help_link_start = '<a href="%{url}" target="_blank" rel="noopener noreferrer" class="help-link">'.html_safe % {
      url: help_url
    }
    help_link_end = '</a>'.html_safe

    _(
      "You're receiving this email because of your account on %{host}. %{manage_label_subscriptions_link_start}" \
        "Manage label subscriptions%{manage_label_subscriptions_link_end} &middot; " \
        "%{help_link_start}Help%{help_link_end}"
    ).html_safe % {
      host: gitlab_host_link(format),
      manage_label_subscriptions_link_start: manage_label_subscriptions_link_start,
      manage_label_subscriptions_link_end: manage_label_subscriptions_link_end,
      help_link_start: help_link_start,
      help_link_end: help_link_end
    }
  end

  def notification_reason_text_with_manage_notifications_and_help_links(reason:, format:)
    manage_notifications_link_start =
      '<a href="%{url}" target="_blank" rel="noopener noreferrer" class="mng-notif-link">'.html_safe % {
        url: profile_notifications_url
      }
    manage_notifications_link_end = '</a>'.html_safe

    help_link_start = '<a href="%{url}" target="_blank" rel="noopener noreferrer" class="help-link">'.html_safe % {
      url: help_url
    }
    help_link_end = '</a>'.html_safe

    case reason
    when NotificationReason::MENTIONED
      _(
        "You're receiving this email because you have been mentioned on %{host}. " \
          "%{manage_notifications_link_start}Manage all notifications%{manage_notifications_link_end} &middot; " \
          "%{help_link_start}Help%{help_link_end}"
      ).html_safe % {
        host: gitlab_host_link(format),
        manage_notifications_link_start: manage_notifications_link_start,
        manage_notifications_link_end: manage_notifications_link_end,
        help_link_start: help_link_start,
        help_link_end: help_link_end
      }
    else
      _(
        "You're receiving this email because of your account on %{host}. %{manage_notifications_link_start}Manage " \
          "all notifications%{manage_notifications_link_end} &middot; %{help_link_start}Help%{help_link_end}"
      ).html_safe % {
        host: gitlab_host_link(format),
        manage_notifications_link_start: manage_notifications_link_start,
        manage_notifications_link_end: manage_notifications_link_end,
        help_link_start: help_link_start,
        help_link_end: help_link_end
      }
    end
  end

  def notification_reason_text_without_links(reason:, format:)
    case reason
    when NotificationReason::OWN_ACTIVITY
      _("You're receiving this email because of your activity on %{host}.").html_safe % {
        host: gitlab_host_link(format)
      }
    when NotificationReason::ASSIGNED
      _("You're receiving this email because you have been assigned an item on %{host}.").html_safe % {
        host: gitlab_host_link(format)
      }
    when NotificationReason::MENTIONED
      _("You're receiving this email because you have been mentioned on %{host}.").html_safe % {
        host: gitlab_host_link(format)
      }
    else
      _("You're receiving this email because of your account on %{host}.").html_safe % {
        host: gitlab_host_link(format)
      }
    end
  end
end

EmailsHelper.prepend_mod_with('EmailsHelper')
