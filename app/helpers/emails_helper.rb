module EmailsHelper

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
          "url" => url,
          }
        }

      content_tag :script, type: 'application/ld+json' do
        data.to_json.html_safe
      end
    end
  end

  def action_title(url)
    return unless url
    ["merge_requests", "issues", "commit"].each do |action|
      if url.split("/").include?(action)
        return "View #{action.humanize.singularize}"
      end
    end

    nil
  end

  def color_email_diff(diffcontent)
    formatter = Rouge::Formatters::HTML.new(css_class: 'highlight', inline_theme: 'github')
    lexer = Rouge::Lexers::Diff
    raw formatter.format(lexer.lex(diffcontent))
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
end
