# Dealing with email in development

## Sent emails

To view rendered emails "sent" in your development instance, visit
[`/rails/letter_opener`](http://localhost:3000/rails/letter_opener).

## Mailer previews

Rails provides a way to preview our mailer templates in HTML and plaintext using
dummy data.

The previews live in [`spec/mailers/previews`][previews] and can be viewed at
[`/rails/mailers`](http://localhost:3000/rails/mailers).

See the [Rails guides] for more info.

[previews]: https://gitlab.com/gitlab-org/gitlab-ce/tree/master/spec/mailers/previews
[Rails guides]: http://guides.rubyonrails.org/action_mailer_basics.html#previewing-emails

## Incoming email

1. Go to the GitLab installation directory.

1. Find the `incoming_email` section in `config/gitlab.yml`, enable the
   feature and fill in the details for your specific IMAP server and email
   account:

    Configuration for Gmail / Google Apps, assumes mailbox gitlab-incoming@gmail.com

    ```yaml
    incoming_email:
      enabled: true

      # The email address including the `%{key}` placeholder that will be replaced to reference the item being replied to.
      # The placeholder can be omitted but if present, it must appear in the "user" part of the address (before the `@`).
      address: "gitlab-incoming+%{key}@gmail.com"

      # Email account username
      # With third party providers, this is usually the full email address.
      # With self-hosted email servers, this is usually the user part of the email address.
      user: "gitlab-incoming@gmail.com"
      # Email account password
      password: "[REDACTED]"

      # IMAP server host
      host: "imap.gmail.com"
      # IMAP server port
      port: 993
      # Whether the IMAP server uses SSL
      ssl: true
      # Whether the IMAP server uses StartTLS
      start_tls: false

      # The mailbox where incoming mail will end up. Usually "inbox".
      mailbox: "inbox"
      # The IDLE command timeout.
      idle_timeout: 60
    ```

    As mentioned, the part after `+` is ignored, and this will end up in the mailbox for `gitlab-incoming@gmail.com`.

1. Uncomment the `mail_room` line in your `Procfile`:

    ```yaml
    mail_room: bundle exec mail_room -q -c config/mail_room.yml
    ```

1. Restart GitLab:

    ```sh
    bundle exec foreman start
    ```

1. Verify that everything is configured correctly:

    ```sh
    bundle exec rake gitlab:incoming_email:check RAILS_ENV=development
    ```

1. Reply by email should now be working.

---

[Return to Development documentation](README.md)
