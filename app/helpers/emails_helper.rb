module EmailsHelper

  # Google Actions
  # https://developers.google.com/gmail/markup/reference/go-to-action
  def email_action(options)
    data = {
      "@context" => "http://schema.org",
      "@type" => "EmailMessage",
      "action" => {
        "@type" => "ViewAction",
        "name" => options[:name],
        "url" => options[:url],
        }
      }

    content_tag :script, type: 'application/ld+json' do
      data.to_json.html_safe
    end
  end
end
