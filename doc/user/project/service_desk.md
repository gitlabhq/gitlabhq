---
stage: Plan
group: Certify
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Service Desk **(FREE)**

> Moved to GitLab Free in 13.2.

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

For example, let's assume you develop a game for iOS or Android.
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

Users with Maintainer and higher access in a project can configure Service Desk.

Service Desk issues are [confidential](issues/confidential_issues.md), so they are
only visible to project members. In GitLab 11.7 we updated the generated email
address format. The older format is still supported, so existing aliases or
contacts still work.

If you have [templates](description_templates.md) in your repository, you can optionally select
one from the selector menu to append it to all Service Desk issues.

To enable Service Desk in your project:

1. (GitLab self-managed only) [Set up incoming email](../../administration/incoming_email.md#set-it-up) for the GitLab instance.
   We recommend using [email sub-addressing](../../administration/incoming_email.md#email-sub-addressing),
   but you can also use [catch-all mailboxes](../../administration/incoming_email.md#catch-all-mailbox).
1. In a project, in the left sidebar, go to **Settings > General** and expand the **Service Desk** section.
1. Enable the **Activate Service Desk** toggle. This reveals a unique email address to email issues
   to the project.

Service Desk is now enabled for this project! To access it in a project, in the left sidebar, select
**Issues > Service Desk**.

WARNING:
Anyone in your project can use the Service Desk email address to create an issue in this project, **regardless
of their access level** to your GitLab instance.

To improve your project's security, we recommend the following:

- Put the Service Desk email address behind an alias on your email system so you can change it later.
- [Enable Akismet](../../integration/akismet.md) on your GitLab instance to add spam checking to this service.
  Unblocked email spam can result in many spam issues being created.

The unique internal email address is visible to project members with Maintainer (or higher)
[permission level](../permissions.md)
in your GitLab instance. However, when using an email alias externally, an end user
(issue creator) cannot see the internal email address displayed in the information note.

### Using customized email templates

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/2460) in GitLab Premium 12.7.
> - Moved to GitLab Free in 13.2.

An email is sent to the author when:

- A user submits a new issue using Service Desk.
- A new note is created on a Service Desk issue.

You can customize the body of these email messages with templates.
Save your templates in the `.gitlab/service_desk_templates/`
directory in your repository.

With Service Desk, you can use templates for:

- [Thank you emails](#thank-you-email)
- [New note emails](#new-note-email)
- [New Service Desk issues](#new-service-desk-issues)

#### Thank you email

When a user submits an issue through Service Desk, GitLab sends a **thank you email**.
You must name the template file `thank_you.md`.

You can use these placeholders to be automatically replaced in each email:

- `%{ISSUE_ID}`: issue IID
- `%{ISSUE_PATH}`: project path appended with the issue IID

Because Service Desk issues are created as [confidential](issues/confidential_issues.md) (only project members can see them),
the response email does not contain the issue link.

#### New note email

When a user-submitted issue receives a new comment, GitLab sends a **new note email**.
You must name the template file `new_note.md`.

You can use these placeholders to be automatically replaced in each email:

- `%{ISSUE_ID}`: issue IID
- `%{ISSUE_PATH}`: project path appended with the issue IID
- `%{NOTE_TEXT}`: note text

#### New Service Desk issues

You can select one [issue description template](description_templates.md#create-an-issue-template)
**per project** to be appended to every new Service Desk issue's description.
Issue description templates should reside in your repository's `.gitlab/issue_templates/` directory.

To use a custom issue template with Service Desk, in your project:

1. [Create a description template](description_templates.md#create-an-issue-template)
1. Go to **Settings > General > Service Desk**.
1. From the dropdown **Template to append to all Service Desk issues**, select your template.

### Using a custom email display name

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/7529) in GitLab 12.8.

You can customize the email display name. Emails sent from Service Desk have
this name in the `From` header. The default display name is `GitLab Support Bot`.

To edit the custom email display name:

1. In a project, go to **Settings > General > Service Desk**.
1. Enter a new name in **Email display name**.
1. Select **Save Changes**.

### Using a custom email address **(FREE SELF)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/2201) in GitLab Premium 13.0.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/284656) in GitLab 13.8.

It is possible to customize the email address used by Service Desk. To do this, you must configure
both a [custom mailbox](#configuring-a-custom-mailbox) and a
[custom suffix](#configuring-a-custom-email-address-suffix).

#### Configuring a custom mailbox

NOTE:
On GitLab.com a custom mailbox is already configured with `contact-project+%{key}@incoming.gitlab.com` as the email address, so you only have to configure the
[custom suffix](#configuring-a-custom-email-address-suffix) in project settings.

Using the `service_desk_email` configuration, you can customize the mailbox
used by Service Desk. This allows you to have a separate email address for
Service Desk by also configuring a [custom suffix](#configuring-a-custom-email-address-suffix)
in project settings.

The `address` must include the `+%{key}` placeholder within the 'user'
portion of the address, before the `@`. This is used to identify the project
where the issue should be created.

NOTE:
The `service_desk_email` and `incoming_email` configurations should
always use separate mailboxes. This is important, because emails picked from
`service_desk_email` mailbox are processed by a different worker and it would
not recognize `incoming_email` emails.

To configure a custom mailbox for Service Desk with IMAP, add the following snippets to your configuration file in full:

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

The configuration options are the same as for configuring
[incoming email](../../administration/incoming_email.md#set-it-up).

##### Microsoft Graph

> Introduced in [GitLab 13.11](https://gitlab.com/gitlab-org/gitlab/-/issues/214900)

Service Desk can be configured to read Microsoft Exchange Online mailboxes with the Microsoft
Graph API instead of IMAP. Follow the [documentation in the incoming email section for setting up an OAuth2 application for Microsoft Graph](../../administration/incoming_email.md#microsoft-graph).

- Example for Omnibus GitLab installations:

  ```ruby
  gitlab_rails['service_desk_email_enabled'] = true
  gitlab_rails['service_desk_email_address'] = "project_contact+%{key}@example.onmicrosoft.com"
  gitlab_rails['service_desk_email_email'] = "project_contact@example.onmicrosoft.com"
  gitlab_rails['service_desk_email_mailbox_name'] = "inbox"
  gitlab_rails['service_desk_email_log_file'] = "/var/log/gitlab/mailroom/mail_room_json.log"
  gitlab_rails['service_desk_inbox_method'] = 'microsoft_graph'
  gitlab_rails['service_desk_inbox_options'] = {
   'tenant_id': '<YOUR-TENANT-ID>',
   'client_id': '<YOUR-CLIENT-ID>',
   'client_secret': '<YOUR-CLIENT-SECRET>',
   'poll_interval': 60  # Optional
  }
  ```

The Microsoft Graph API is not yet supported in source installations. See [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/326169) for more details.

#### Configuring a custom email address suffix

You can set a custom suffix in your project's Service Desk settings once you have configured a [custom mailbox](#configuring-a-custom-mailbox).
It can contain only lowercase letters (`a-z`), numbers (`0-9`), or underscores (`_`).

When configured, the custom suffix creates a new Service Desk email address, consisting of the
`service_desk_email_address` setting and a key of the format: `<project_full_path>-<custom_suffix>`

For example, suppose the `mygroup/myproject` project Service Desk settings has the following configured:

- Project name suffix is set to `support`.
- Service Desk email address is configured to `contact+%{key}@example.com`.

The Service Desk email address for this project is: `contact+mygroup-myproject-support@example.com`.
The [incoming email](../../administration/incoming_email.md) address still works.

## Using Service Desk

You can use Service Desk to [create an issue](#as-an-end-user-issue-creator) or [respond to one](#as-a-responder-to-the-issue).
In these issues, you can also see our friendly neighborhood [Support Bot](#support-bot-user).

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
