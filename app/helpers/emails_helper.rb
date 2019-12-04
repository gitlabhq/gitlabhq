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

  private

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

EmailsHelper.prepend_if_ee('EE::EmailsHelper')
