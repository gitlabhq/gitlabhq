require "#{Rails.root}/app/helpers/emails_helper"
require 'action_view/helpers'
extend ActionView::Helpers

include ActionView::Context
include EmailsHelper

namespace :gitlab do
  desc "Email google whitelisting email with example email for actions in inbox"
  task mail_google_schema_whitelisting: :environment do
    subject = "Rails | Implemented feature"
    url = "#{Gitlab.config.gitlab.url}/base/rails-project/issues/#{rand(1..100)}#note_#{rand(10..1000)}"
    schema = email_action(url)
    body = email_template(schema, url)
    mail = Notify.test_email("schema.whitelisting+sample@gmail.com", subject, body.html_safe)
    if send_now
      mail.deliver
    else
      puts "WOULD SEND:"
    end
    puts mail
  end

  def email_template(schema, url)
    "<html lang='en'>
      <head>
        <meta content='text/html; charset=utf-8' http-equiv='Content-Type'>
          <title>
            GitLab
          </title>
        </meta>
      </head>
      <style>
        img {
          max-width: 100%;
          height: auto;
        }
        p.details {
          font-style:italic;
          color:#777
        }
        .footer p {
          font-size:small;
          color:#777
        }
      </style>
      <body>
        <div class='content'>
          <div>
           <p>I like it :+1: </p>
          </div>
        </div>

        <div class='footer' style='margin-top: 10px;'>
          <p>
          <br>
            You're receiving this notification because you are a member of the Base / Rails Project project team.
            <a href=\"#{url}\">View it on GitLab</a>
            #{schema}
          </p>
        </div>
      </body>
    </html>"
  end

  def send_now
    if ENV['SEND'] == "true"
      true
    else
      false
    end
  end
end
