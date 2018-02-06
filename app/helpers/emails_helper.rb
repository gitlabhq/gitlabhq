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

  def reset_token_expire_message
    link_tag = link_to('request a new one', new_user_password_url(user_email: @user.email))
    msg = "This link is valid for #{password_reset_token_valid_time}.  "
    msg << "After it expires, you can #{link_tag}."
  end

  def header_logo
    if brand_item && brand_item.header_logo?
      image_tag(
        brand_item.header_logo,
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

  # "You are receiving this email because #{reason}"
  def notification_reason_text(reason)
    string = case reason
             when NotificationReason::OWN_ACTIVITY
               'of your activity'
             when NotificationReason::ASSIGNED
               'you have been assigned an item'
             when NotificationReason::MENTIONED
               'you have been mentioned'
             else
               'of your account'
             end

    "#{string} on #{Gitlab.config.gitlab.host}"
  end
end
