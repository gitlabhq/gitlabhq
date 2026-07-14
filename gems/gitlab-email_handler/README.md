# gitlab-email_handler

Incoming email identification for GitLab.

This gem owns the parsing rules for incoming email keys (the `incoming+...` part
of an email address). It is the single source of truth for the reply key
regular expressions that were previously duplicated in `SentNotification` and
the `Gitlab::Email::Handler` classes.

It is pure and dependency-free: it parses email keys and returns the identified
target. It does not know how a target is resolved to a cell or how email is
forwarded — that is the responsibility of the consumer (the mail_room service).

## Responsibilities

- `Gitlab::EmailHandler::ReplyKey` — regular expressions and constants for
  parsing reply keys and handler keys.
- `Gitlab::EmailHandler::Matchers::*` — one matcher per handler. Each mirrors a
  handler's mail key parsing. Pure regex, no database or network access.
- `Gitlab::EmailHandler::Identifier` — tries each matcher in handler precedence
  order and returns an `Identification`.
- `Gitlab::EmailHandler::Identification` — the parse result. `#target` returns
  the identified `Target`, or `nil` when the email can't be identified.
- `Gitlab::EmailHandler::Target` — a value object describing the identified
  resource: a `kind` (`:project_id`, `:namespace_id`, `:route`, or
  `:service_desk_custom_email`) and its `value`.
- `Gitlab::EmailHandler::CustomEmail` — recognises and normalises custom Service
  Desk email addresses (stripping `+verify` / `+<reply_key>` sub-addressing).

## Identification

Targets are derived as follows:

- project id keys → `Target.project_id`
- partitioned reply keys that encode a namespace id → `Target.namespace_id`
  (decoded offline)
- legacy project paths → `Target.route` (located by the top-level namespace)
- custom Service Desk emails → `Target.service_desk_custom_email`

Emails that can't be identified (legacy reply keys without an encoded namespace,
opaque service desk keys) return `nil`.

## Loading

```ruby
require 'gitlab/email_handler'

identification = Gitlab::EmailHandler::Identifier.call(mail_key)
identification&.target # => #<Target kind=:project_id value=42> or nil
```
