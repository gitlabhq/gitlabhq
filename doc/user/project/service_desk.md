---
stage: Plan
group: Certify
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Service Desk **(CORE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/149) in [GitLab Premium](https://about.gitlab.com/pricing/) 9.1.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/214839) to [GitLab Starter](https://about.gitlab.com/pricing/) in 13.0.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/215364) to [GitLab Core](https://about.gitlab.com/pricing/) in 13.2.

Service Desk is a module that allows your team to connect
with any external party through email, without any external tools.
An ongoing conversation in the same place as where your software
is built ensures user feedback ends up where it's needed.

With Service Desk, you can provide efficient email support to your customers. They can
email you bug reports, feature requests, or general feedback. They all end up in your
GitLab project as new issues. In turn, your team can respond directly from the project.

As Service Desk is built right into GitLab itself, the complexity and inefficiencies
of multiple tools and external integrations are eliminated. This significantly shortens
the cycle time from feedback to software update.

For an overview, check the video demonstration on [GitLab Service Desk](https://about.gitlab.com/blog/2017/05/09/demo-service-desk/).

## How it works

GitLab Service Desk enables people to create issues in your
GitLab instance without needing their own user account.

It provides a unique email address for end users to create issues in a project.
Follow-up notes can be sent either through the GitLab interface or by email. End
users only see the thread through email.

For instance, let's assume you develop a game for iOS or Android.
The codebase is hosted in your GitLab instance, built and deployed
with GitLab CI/CD.

Here's how Service Desk works for you:

1. You provide a project-specific email address to your paying customers, who can email you directly
   from the application.
1. Each email they send creates an issue in the appropriate project.
1. Your team members navigate to the Service Desk issue tracker, where they can see new support
   requests and respond inside associated issues.
1. Your team communicates back and forth with the customer to understand the request.
1. Your team starts working on implementing code to solve your customer's problem.
1. When your team finishes the implementation, whereupon the merge request is merged and the issue
   is closed automatically.
1. The customer's requests are handled through email, without ever having access to your
   GitLab instance.
1. Your team saved time by not having to leave GitLab (or setup any integrations) to follow up with
   your customer.

## Configuring Service Desk

NOTE:
Service Desk is enabled on GitLab.com.
You can skip step 1 below; you only need to enable it per project.

If you have project maintainer access you have the option to set up Service Desk. Follow these steps:

1. [Set up incoming email](../../administration/incoming_email.md#set-it-up) for the GitLab instance.
   We recommend using [email sub-addressing](../../administration/incoming_email.md#email-sub-addressing),
   but in GitLab 11.7 and later you can also use [catch-all mailboxes](../../administration/incoming_email.md#catch-all-mailbox).
1. Navigate to your project's **Settings > General** and locate the **Service Desk** section.
1. Enable the **Activate Service Desk** toggle. This reveals a unique email address to email issues
   to the project. These issues are [confidential](issues/confidential_issues.md), so they are
   only visible to project members. Note that in GitLab 11.7, we updated the generated email
   address's format. The older format is still supported, however, allowing existing aliases or
   contacts to continue working.

   WARNING:
   This email address can be used by anyone to create an issue on this project, regardless
   of their access level to your GitLab instance. We recommend **putting this behind an alias** so it can be
   changed if needed. We also recommend **[enabling Akismet](../../integration/akismet.md)** on your GitLab
   instance to add spam checking to this service. Unblocked email spam would result in many spam
   issues being created.

   If you have [templates](description_templates.md) in your repository, you can optionally select
   one from the selector menu to append it to all Service Desk issues.

Service Desk is now enabled for this project! You should be able to access it from your project's
**Issues** menu.

![Service Desk Navigation Item](img/service_desk_nav_item.png)

### Using customized email templates

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/2460) in [GitLab Premium](https://about.gitlab.com/pricing/) 12.7.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/214839) to [GitLab Starter](https://about.gitlab.com/pricing/) in 13.0.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/215364) to [GitLab Core](https://about.gitlab.com/pricing/) in 13.2.

An email is sent to the author when:

- A user submits a new issue using Service Desk.
- A new note is created on a Service Desk issue.

The body of these email messages can be customized by using templates. To create a new customized template,
create a new Markdown (`.md`) file inside the `.gitlab/service_desk_templates/`
directory in your repository. Commit and push to your default branch.

#### Thank you email

The **Thank you email** is the email sent to a user after they submit an issue.
The filename of the template has to be `thank_you.md`.
There are a few placeholders you can use which are automatically replaced in the email:

- `%{ISSUE_ID}`: issue IID
- `%{ISSUE_PATH}`: project path appended with the issue IID

As the Service Desk issues are created as confidential (only project members can see them)
the response email does not provide the issue link.

#### New note email

When a user-submitted issue receives a new comment, GitLab sends a **New note email**
to the user. The filename of this template must be `new_note.md`, and you can
use these placeholders in the email:

- `%{ISSUE_ID}`: issue IID
- `%{ISSUE_PATH}`: project path appended with the issue IID
- `%{NOTE_TEXT}`: note text

### Using custom email display name

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/7529) in GitLab 12.8.

You can customize the email display name. Emails sent from Service Desk have
this name in the `From` header. The default display name is `GitLab Support Bot`.

To edit the custom email display name:

1. In a project, go to **Settings > General > Service Desk**.
1. Enter a new name in **Email display name**.
1. Select **Save Changes**.

### Using custom email address

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/2201) in [GitLab Premium](https://about.gitlab.com/pricing/) 13.0.
> - It was [deployed behind a feature flag](../feature_flags.md), disabled by default.
> - [Became enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/284656) on GitLab 13.7.
> - It's enabled on GitLab.com.
> - It's recommended for production use.
> - For GitLab self-managed instances, GitLab administrators can opt to [disable it](#disable-custom-email-address). **(CORE ONLY)**

If the `service_desk_email` feature flag is enabled, then you can
create Service Desk issues by sending emails to the Service Desk email address.
The default address has the following format: `project_contact+%{key}@example.com`.

The `%{key}` part is used to find the project where the issue should be created. The
`%{key}` part combines the path to the project and configurable project name suffix:
`<project_full_path>-<project_name_suffix>`.

You can set the project name suffix in your project's Service Desk settings.
It can contain only lowercase letters (`a-z`), numbers (`0-9`), or underscores (`_`).

NOTE:
The `service_desk_email` and `incoming_email` configurations should
always use separate mailboxes. This is important, because emails picked from
`service_desk_email` mailbox are processed by a different worker and it would
not recognize `incoming_email` emails.

You can add the following snippets to your configuration:

- Example for installations from source:

  ```yaml
  service_desk_email:
    enabled: true
    address: "project_contact+%{key}@example.com"
    user: "project_support@example.com"
    password: "[REDACTED]"
    host: "imap.gmail.com"
    port: 993
    ssl: true
    start_tls: false
    log_path: "log/mailroom.log"
    mailbox: "inbox"
    idle_timeout: 60
    expunge_deleted: true
  ```

- Example for Omnibus GitLab installations:

  ```ruby
  gitlab_rails['service_desk_email_enabled'] = true

  gitlab_rails['service_desk_email_address'] = "project_contact+%{key}@gmail.com"

  gitlab_rails['service_desk_email_email'] = "project_support@gmail.com"

  gitlab_rails['service_desk_email_password'] = "[REDACTED]"

  gitlab_rails['service_desk_email_mailbox_name'] = "inbox"

  gitlab_rails['service_desk_email_idle_timeout'] = 60

  gitlab_rails['service_desk_email_log_file'] = "/var/log/gitlab/mailroom/mail_room_json.log"

  gitlab_rails['service_desk_email_host'] = "imap.gmail.com"

  gitlab_rails['service_desk_email_port'] = 993

  gitlab_rails['service_desk_email_ssl'] = true

  gitlab_rails['service_desk_email_start_tls'] = false
  ```

In this case, suppose the `mygroup/myproject` project Service Desk settings has the project name
suffix set to `support`, and a user sends an email to `project_contact+mygroup-myproject-support@example.com`.
As a result, a new Service Desk issue is created from this email in the `mygroup/myproject` project.

The configuration options are the same as for configuring
[incoming email](../../administration/incoming_email.md#set-it-up).

#### Disable custom email address **(CORE ONLY)**

Service Desk custom email is under development but ready for production use.
It is deployed behind a feature flag that is **enabled by default**.

To disable it:

```ruby
Feature.disable(:service_desk_custom_address)
```

To enable it:

```ruby
Feature.enable(:service_desk_custom_address)
```

## Using Service Desk

There are a few ways Service Desk can be used.

### As an end user (issue creator)

To create a Service Desk issue, an end user does not need to know anything about
the GitLab instance. They just send an email to the address they are given, and
receive an email back confirming receipt:

![Service Desk enabled](img/service_desk_confirmation_email.png)

This also gives the end user an option to unsubscribe.

If they don't choose to unsubscribe, then any new comments added to the issue
are sent as emails:

![Service Desk reply email](img/service_desk_reply.png)

Any responses they send via email are displayed in the issue itself.

### As a responder to the issue

For responders to the issue, everything works just like other GitLab issues.
GitLab displays a familiar-looking issue tracker where responders can see
issues created through customer support requests, and filter or interact with them.

![Service Desk Issue tracker](img/service_desk_issue_tracker.png)

Messages from the end user are shown as coming from the special
[Support Bot user](../../subscriptions/self_managed/index.md#billable-users).
You can read and write comments as you normally do in GitLab:

![Service Desk issue thread](img/service_desk_thread.png)

Note that:

- The project's visibility (private, internal, public) does not affect Service Desk.
- The path to the project, including its group or namespace, are shown in emails.

### Support Bot user

Behind the scenes, Service Desk works by the special Support Bot user creating issues. This user
does not count toward the license limit count.
