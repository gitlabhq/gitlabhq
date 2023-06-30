---
stage: Monitor
group: Respond
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Service Desk **(FREE)**

> Moved to GitLab Free in 13.2.

With Service Desk, your customers
can email you bug reports, feature requests, or general feedback.
Service Desk provides a unique email address, so they don't need their own GitLab accounts.

Service Desk emails are created in your GitLab project as new issues.
Your team can respond directly from the project, while customers interact with the thread only
through email.

## Service Desk workflow

For example, let's assume you develop a game for iOS or Android.
The codebase is hosted in your GitLab instance, built and deployed
with GitLab CI/CD.

Here's how Service Desk works for you:

1. You provide a project-specific email address to your paying customers, who can email you directly
   from the application.
1. Each email they send creates an issue in the appropriate project.
1. Your team members go to the Service Desk issue tracker, where they can see new support
   requests and respond inside associated issues.
1. Your team communicates with the customer to understand the request.
1. Your team starts working on implementing code to solve your customer's problem.
1. When your team finishes the implementation, the merge request is merged and the issue
   is closed automatically.

Meanwhile:

- The customer interacts with your team entirely through email, without needing access to your
  GitLab instance.
- Your team saves time by not having to leave GitLab (or set up integrations) to follow up with
  your customer.

## Configure Service Desk

To start using Service Desk for a project, you must first turn it on.
By default, Service Desk is turned off.

Prerequisites:

- You must have at least the Maintainer role for the project.
- On GitLab self-managed, you must [set up incoming email](../../administration/incoming_email.md#set-it-up)
  for the GitLab instance. You should use
  [email sub-addressing](../../administration/incoming_email.md#email-sub-addressing),
  but you can also use [catch-all mailboxes](../../administration/incoming_email.md#catch-all-mailbox).
  To do this, you must have administrator access.
- You must have enabled [issue](settings/index.md#configure-project-visibility-features-and-permissions)
  tracker for the project.

To enable Service Desk in your project:

1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find your project.
1. Select **Settings > General**.
1. Expand **Service Desk**.
1. Turn on the **Activate Service Desk** toggle.
1. Optional. Complete the fields.
   - [Add a suffix](#configure-a-custom-email-address-suffix) to your Service Desk email address.
   - If the list below **Template to append to all Service Desk issues** is empty, create a
     [description template](description_templates.md) in your repository.
1. Select **Save changes**.

Service Desk is now enabled for this project.
If anyone sends an email to the address available below **Email address to use for Service Desk**,
GitLab creates a confidential issue with the email's content.

### Improve your project's security

To improve your Service Desk project's security, you should:

- Put the Service Desk email address behind an alias on your email system so you can change it later.
- [Enable Akismet](../../integration/akismet.md) on your GitLab instance to add spam checking to this service.
  Unblocked email spam can result in many spam issues being created.

### Customize emails sent to the requester

> - Moved from GitLab Premium to GitLab Free in 13.2.
> - `UNSUBSCRIBE_URL`, `SYSTEM_HEADER`, `SYSTEM_FOOTER`, and `ADDITIONAL_TEXT` placeholders [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/285512) in GitLab 15.9.
> - `%{ISSUE_DESCRIPTION}` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/223751) in GitLab 16.0.
> - `%{ISSUE_URL}` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/408793) in GitLab 16.1.

An email is sent to the requester when:

- A requester submits a new ticket by emailing Service Desk.
- A new public comment is added on a Service Desk ticket.
  - Editing a comment does not trigger a new email to be sent.

You can customize the body of these email messages with Service Desk email templates. The templates
can include [GitLab Flavored Markdown](../markdown.md) and [some HTML tags](../markdown.md#inline-html).
For example, you can format the emails to include a header and footer in accordance with your
organization's brand guidelines. You can also include the following placeholders to display dynamic
content specific to the Service Desk ticket or your GitLab instance.

| Placeholder            | `thank_you.md`         | `new_note.md`          | Description
| ---------------------- | ---------------------- | ---------------------- | -----------
| `%{ISSUE_ID}`          | **{check-circle}** Yes | **{check-circle}** Yes | Ticket IID.
| `%{ISSUE_PATH}`        | **{check-circle}** Yes | **{check-circle}** Yes | Project path appended with the ticket IID.
| `%{ISSUE_URL}`         | **{check-circle}** Yes | **{check-circle}** Yes | URL of the ticket. External participants can only view the ticket if the project is public and ticket is not confidential (Service Desk tickets are confidential by default).
| `%{ISSUE_DESCRIPTION}` | **{check-circle}** Yes | **{check-circle}** Yes | Ticket description. If a user has edited the description, it may contain sensitive information that is not intended to be delivered to external participants. Use this placeholder with care and ideally only if you never modify descriptions or your team is aware of the template design.
| `%{UNSUBSCRIBE_URL}`   | **{check-circle}** Yes | **{check-circle}** Yes | Unsubscribe URL.
| `%{NOTE_TEXT}`         | **{dotted-circle}** No | **{check-circle}** Yes | The new comment added to the ticket by a user. Take care to include this placeholder in `new_note.md`. Otherwise, the requesters may never see the updates on their Service Desk ticket.

#### Thank you email

When a requester submits an issue through Service Desk, GitLab sends a **thank you email**.
Without additional configuration, GitLab sends the default thank you email.

To create a custom thank you email template:

1. In the `.gitlab/service_desk_templates/` directory of your repository, create a file named `thank_you.md`.
1. Populate the Markdown file with text, [GitLab Flavored Markdown](../markdown.md),
   [some selected HTML tags](../markdown.md#inline-html), and placeholders to customize the reply
   to Service Desk requesters.

#### New note email

When a Service Desk ticket has a new public comment, GitLab sends a **new note email**.
Without additional configuration, GitLab sends the content of the comment.

To keep your emails on brand, you can create a custom new note email template. To do so:

1. In the `.gitlab/service_desk_templates/` directory in your repository, create a file named `new_note.md`.
1. Populate the Markdown file with text, [GitLab Flavored Markdown](../markdown.md),
   [some selected HTML tags](../markdown.md#inline-html), and placeholders to customize the new note
   email. Be sure to include the `%{NOTE_TEXT}` in the template to make sure the email recipient can
   read the contents of the comment.

#### Instance-level email header, footer, and additional text **(FREE SELF)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/344819) in GitLab 15.9.

Instance administrators can add a header, footer or additional text to the GitLab instance and apply
them to all emails sent from GitLab. If you're using a custom `thank_you.md` or `new_note.md`, to include
this content, add `%{SYSTEM_HEADER}`, `%{SYSTEM_FOOTER}`, or `%{ADDITIONAL_TEXT}` to your templates.

For more information, see [System header and footer messages](../admin_area/appearance.md#system-header-and-footer-messages) and [custom additional text](../admin_area/settings/email.md#custom-additional-text).

### Use a custom template for Service Desk tickets

You can select one [description template](description_templates.md#create-an-issue-template)
**per project** to be appended to every new Service Desk ticket's description.

You can set description templates at various levels:

- The entire [instance](description_templates.md#set-instance-level-description-templates).
- A specific [group or subgroup](description_templates.md#set-group-level-description-templates).
- A specific [project](description_templates.md#set-a-default-template-for-merge-requests-and-issues).

The templates are inherited. For example, in a project, you can also access templates set for the instance, or the project's parent groups.

Prerequisite:

- You must have [created a description template](description_templates.md#create-an-issue-template).

To use a custom description template with Service Desk:

1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find your project.
1. Select **Settings > General**.
1. Expand **Service Desk**.
1. From the dropdown list **Template to append to all Service Desk issues**, search or select your template.

### Support Bot user

Behind the scenes, Service Desk works by the special Support Bot user creating issues.
This user isn't a [billable user](../../subscriptions/self_managed/index.md#billable-users),
so it does not count toward the license limit count.

In GitLab 16.0 and earlier, comments generated from Service Desk emails show `GitLab Support Bot`
as the author. In [GitLab 16.1 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/226995),
these comments show the email of the user who sent the email.
This feature only applies to comments made in GitLab 16.1 and later.

#### Change the Support Bot's display name

You can change the display name of the Support Bot user. Emails sent from Service Desk have
this name in the `From` header. The default display name is `GitLab Support Bot`.

To edit the custom email display name:

1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find your project.
1. Select **Settings > General**.
1. Expand **Service Desk**.
1. Below **Email display name**, enter a new name.
1. Select **Save changes**.

### Use a custom email address **(FREE SELF)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/2201) in GitLab 13.0.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/284656) in GitLab 13.8.

You can use a custom email address with Service Desk.

To do this, you must configure
a [custom mailbox](#configure-a-custom-mailbox). You can also configure a
[custom suffix](#configure-a-custom-email-address-suffix).

#### Configure a custom mailbox

NOTE:
On GitLab.com a custom mailbox is already configured with `contact-project+%{key}@incoming.gitlab.com` as the email address, you can still configure the
[custom suffix](#configure-a-custom-email-address-suffix) in project settings.

Service Desk uses the [incoming email](../../administration/incoming_email.md)
configuration by default. However, by using the `service_desk_email` configuration,
you can customize the mailbox used by Service Desk. This allows you to have
a separate email address for Service Desk by also configuring a [custom suffix](#configure-a-custom-email-address-suffix)
in project settings.

Prerequisites:

- The `address` must include the `+%{key}` placeholder in the `user` portion of the address,
  before the `@`. The placeholder is used to identify the project where the issue should be created.
- The `service_desk_email` and `incoming_email` configurations must always use separate mailboxes
  to make sure Service Desk emails are processed correctly.

To configure a custom mailbox for Service Desk with IMAP, add the following snippets to your configuration file in full:

::Tabs

:::TabTitle Linux package (Omnibus)

NOTE:
In GitLab 15.3 and later, Service Desk uses `webhook` (internal API call) by default instead of enqueuing a Sidekiq job.
To use `webhook` on a Linux package installation running GitLab 15.3, you must generate a secret file.
For more information, see [merge request 5927](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/5927).
In GitLab 15.4, reconfiguring a Linux package installation generates this secret file automatically, so no
secret file configuration setting is needed.
For more information, see [issue 1462](https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/1462).

```ruby
gitlab_rails['service_desk_email_enabled'] = true
gitlab_rails['service_desk_email_address'] = "project_contact+%{key}@gmail.com"
gitlab_rails['service_desk_email_email'] = "project_contact@gmail.com"
gitlab_rails['service_desk_email_password'] = "[REDACTED]"
gitlab_rails['service_desk_email_mailbox_name'] = "inbox"
gitlab_rails['service_desk_email_idle_timeout'] = 60
gitlab_rails['service_desk_email_log_file'] = "/var/log/gitlab/mailroom/mail_room_json.log"
gitlab_rails['service_desk_email_host'] = "imap.gmail.com"
gitlab_rails['service_desk_email_port'] = 993
gitlab_rails['service_desk_email_ssl'] = true
gitlab_rails['service_desk_email_start_tls'] = false
```

:::TabTitle Self-compiled (source)

```yaml
service_desk_email:
  enabled: true
  address: "project_contact+%{key}@example.com"
  user: "project_contact@example.com"
  password: "[REDACTED]"
  host: "imap.gmail.com"
  delivery_method: webhook
  secret_file: .gitlab-mailroom-secret
  port: 993
  ssl: true
  start_tls: false
  log_path: "log/mailroom.log"
  mailbox: "inbox"
  idle_timeout: 60
  expunge_deleted: true
```

::EndTabs

The configuration options are the same as for configuring
[incoming email](../../administration/incoming_email.md#set-it-up).

##### Use encrypted credentials

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/108279) in GitLab 15.9.

Instead of having the Service Desk email credentials stored in plaintext in the configuration files, you can optionally
use an encrypted file for the incoming email credentials.

Prerequisites:

- To use encrypted credentials, you must first enable the
  [encrypted configuration](../../administration/encrypted_configuration.md).

The supported configuration items for the encrypted file are:

- `user`
- `password`

::Tabs

:::TabTitle Linux package (Omnibus)

1. If initially your Service Desk configuration in `/etc/gitlab/gitlab.rb` looked like:

   ```ruby
   gitlab_rails['service_desk_email_email'] = "service-desk-email@mail.example.com"
   gitlab_rails['service_desk_email_password'] = "examplepassword"
   ```

1. Edit the encrypted secret:

   ```shell
   sudo gitlab-rake gitlab:service_desk_email:secret:edit EDITOR=vim
   ```

1. Enter the unencrypted contents of the Service Desk email secret:

   ```yaml
   user: 'service-desk-email@mail.example.com'
   password: 'examplepassword'
   ```

1. Edit `/etc/gitlab/gitlab.rb` and remove the `service_desk` settings for `email` and `password`.
1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

:::TabTitle Helm chart (Kubernetes)

Use a Kubernetes secret to store the Service Desk email password. For more information,
read about [Helm IMAP secrets](https://docs.gitlab.com/charts/installation/secrets.html#imap-password-for-service-desk-emails).

:::TabTitle Docker

1. If initially your Service Desk configuration in `docker-compose.yml` looked like:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       image: 'gitlab/gitlab-ee:latest'
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['service_desk_email_email'] = "service-desk-email@mail.example.com"
           gitlab_rails['service_desk_email_password'] = "examplepassword"
   ```

1. Get inside the container, and edit the encrypted secret:

   ```shell
   sudo docker exec -t <container_name> bash
   gitlab-rake gitlab:service_desk_email:secret:edit EDITOR=editor
   ```

1. Enter the unencrypted contents of the Service Desk secret:

   ```yaml
   user: 'service-desk-email@mail.example.com'
   password: 'examplepassword'
   ```

1. Edit `docker-compose.yml` and remove the `service_desk` settings for `email` and `password`.
1. Save the file and restart GitLab:

   ```shell
   docker compose up -d
   ```

:::TabTitle Self-compiled (source)

1. If initially your Service Desk configuration in `/home/git/gitlab/config/gitlab.yml` looked like:

   ```yaml
   production:
     service_desk_email:
       user: 'service-desk-email@mail.example.com'
       password: 'examplepassword'
   ```

1. Edit the encrypted secret:

   ```shell
   bundle exec rake gitlab:service_desk_email:secret:edit EDITOR=vim RAILS_ENVIRONMENT=production
   ```

1. Enter the unencrypted contents of the Service Desk secret:

   ```yaml
   user: 'service-desk-email@mail.example.com'
   password: 'examplepassword'
   ```

1. Edit `/home/git/gitlab/config/gitlab.yml` and remove the `service_desk_email:` settings for `user` and `password`.
1. Save the file and restart GitLab and Mailroom

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

::EndTabs

##### Microsoft Graph

> - Alternative Azure deployments [introduced](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/5978) in GitLab 14.9.
> - [Introduced for self-compiled (source) installs](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/116494) in GitLab 15.11.

Service Desk can be configured to read Microsoft Exchange Online mailboxes with the Microsoft
Graph API instead of IMAP. Set up an OAuth 2.0 application for Microsoft Graph
[the same way as for incoming email](../../administration/incoming_email.md#microsoft-graph).

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb` and add the following lines, substituting
   the values you want:

  ```ruby
  gitlab_rails['service_desk_email_enabled'] = true
  gitlab_rails['service_desk_email_address'] = "project_contact+%{key}@example.onmicrosoft.com"
  gitlab_rails['service_desk_email_email'] = "project_contact@example.onmicrosoft.com"
  gitlab_rails['service_desk_email_mailbox_name'] = "inbox"
  gitlab_rails['service_desk_email_log_file'] = "/var/log/gitlab/mailroom/mail_room_json.log"
  gitlab_rails['service_desk_email_inbox_method'] = 'microsoft_graph'
  gitlab_rails['service_desk_email_inbox_options'] = {
    'tenant_id': '<YOUR-TENANT-ID>',
    'client_id': '<YOUR-CLIENT-ID>',
    'client_secret': '<YOUR-CLIENT-SECRET>',
    'poll_interval': 60  # Optional
  }
  ```

  For Microsoft Cloud for US Government or [other Azure deployments](https://learn.microsoft.com/en-us/graph/deployments),
  configure the `azure_ad_endpoint` and `graph_endpoint` settings. For example:

  ```ruby
  gitlab_rails['service_desk_email_inbox_options'] = {
    'azure_ad_endpoint': 'https://login.microsoftonline.us',
    'graph_endpoint': 'https://graph.microsoft.us',
    'tenant_id': '<YOUR-TENANT-ID>',
    'client_id': '<YOUR-CLIENT-ID>',
    'client_secret': '<YOUR-CLIENT-SECRET>',
    'poll_interval': 60  # Optional
  }
  ```

:::TabTitle Helm chart (Kubernetes)

1. Create the [Kubernetes Secret containing the OAuth 2.0 application client secret](https://docs.gitlab.com/charts/installation/secrets.html#microsoft-graph-client-secret-for-service-desk-emails):

   ```shell
   kubectl create secret generic service-desk-email-client-secret --from-literal=secret=<YOUR-CLIENT_SECRET>
   ```

1. Create the [Kubernetes Secret for the GitLab Service Desk email auth token](https://docs.gitlab.com/charts/installation/secrets.html#gitlab-service-desk-email-auth-token).
   Replace `<name>` with the name of the [Helm release name](https://helm.sh/docs/intro/using_helm/) for the GitLab installation:

   ```shell
   kubectl create secret generic <name>-service-desk-email-auth-token --from-literal=authToken=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32 | base64)
   ```

1. Export the Helm values:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Edit `gitlab_values.yaml`:

   ```yaml
   global:
     appConfig:
     serviceDeskEmail:
       enabled: true
       address: "project_contact+%{key}@example.onmicrosoft.com"
       user: "project_contact@example.onmicrosoft.com"
       mailbox: inbox
       inboxMethod: microsoft_graph
       azureAdEndpoint: https://login.microsoftonline.com
       graphEndpoint: https://graph.microsoft.com
       tenantId: "YOUR-TENANT-ID"
       clientId: "YOUR-CLIENT-ID"
       clientSecret:
         secret: service-desk-email-client-secret
         key: secret
       deliveryMethod: webhook
       authToken:
         secret: <name>-service-desk-email-auth-token
         key: authToken
   ```

    For Microsoft Cloud for US Government or [other Azure deployments](https://learn.microsoft.com/en-us/graph/deployments),
configure the `azureAdEndpoint` and `graphEndpoint` settings. These fields are case-sensitive:

   ```yaml
   global:
     appConfig:
     serviceDeskEmail:
       [..]
       azureAdEndpoint: https://login.microsoftonline.us
       graphEndpoint: https://graph.microsoft.us
       [..]
   ```

1. Save the file and apply the new values:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

:::TabTitle Docker

1. Edit `docker-compose.yml`:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['service_desk_email_enabled'] = true
           gitlab_rails['service_desk_email_address'] = "project_contact+%{key}@example.onmicrosoft.com"
           gitlab_rails['service_desk_email_email'] = "project_contact@example.onmicrosoft.com"
           gitlab_rails['service_desk_email_mailbox_name'] = "inbox"
           gitlab_rails['service_desk_email_log_file'] = "/var/log/gitlab/mailroom/mail_room_json.log"
           gitlab_rails['service_desk_email_inbox_method'] = 'microsoft_graph'
           gitlab_rails['service_desk_email_inbox_options'] = {
             'tenant_id': '<YOUR-TENANT-ID>',
             'client_id': '<YOUR-CLIENT-ID>',
             'client_secret': '<YOUR-CLIENT-SECRET>',
             'poll_interval': 60  # Optional
           }
   ```

1. Save the file and restart GitLab:

   ```shell
   docker compose up -d
   ```

For Microsoft Cloud for US Government or [other Azure deployments](https://learn.microsoft.com/en-us/graph/deployments),
configure the `azure_ad_endpoint` and `graph_endpoint` settings:

1. Edit `docker-compose.yml`:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['service_desk_email_enabled'] = true
           gitlab_rails['service_desk_email_address'] = "project_contact+%{key}@example.onmicrosoft.com"
           gitlab_rails['service_desk_email_email'] = "project_contact@example.onmicrosoft.com"
           gitlab_rails['service_desk_email_mailbox_name'] = "inbox"
           gitlab_rails['service_desk_email_log_file'] = "/var/log/gitlab/mailroom/mail_room_json.log"
           gitlab_rails['service_desk_email_inbox_method'] = 'microsoft_graph'
           gitlab_rails['service_desk_email_inbox_options'] = {
             'azure_ad_endpoint': 'https://login.microsoftonline.us',
             'graph_endpoint': 'https://graph.microsoft.us',
             'tenant_id': '<YOUR-TENANT-ID>',
             'client_id': '<YOUR-CLIENT-ID>',
             'client_secret': '<YOUR-CLIENT-SECRET>',
             'poll_interval': 60  # Optional
           }
   ```

1. Save the file and restart GitLab:

   ```shell
   docker compose up -d
   ```

:::TabTitle Self-compiled (source)

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
     service_desk_email:
       enabled: true
       address: "project_contact+%{key}@example.onmicrosoft.com"
       user: "project_contact@example.onmicrosoft.com"
       mailbox: "inbox"
       delivery_method: webhook
       log_path: "log/mailroom.log"
       secret_file: .gitlab-mailroom-secret
       inbox_method: "microsoft_graph"
       inbox_options:
         tenant_id: "<YOUR-TENANT-ID>"
         client_id: "<YOUR-CLIENT-ID>"
         client_secret: "<YOUR-CLIENT-SECRET>"
         poll_interval: 60  # Optional
   ```

  For Microsoft Cloud for US Government or [other Azure deployments](https://learn.microsoft.com/en-us/graph/deployments),
  configure the `azure_ad_endpoint` and `graph_endpoint` settings. For example:

   ```yaml
     service_desk_email:
       enabled: true
       address: "project_contact+%{key}@example.onmicrosoft.com"
       user: "project_contact@example.onmicrosoft.com"
       mailbox: "inbox"
       delivery_method: webhook
       log_path: "log/mailroom.log"
       secret_file: .gitlab-mailroom-secret
       inbox_method: "microsoft_graph"
       inbox_options:
         azure_ad_endpoint: "https://login.microsoftonline.us"
         graph_endpoint: "https://graph.microsoft.us"
         tenant_id: "<YOUR-TENANT-ID>"
         client_id: "<YOUR-CLIENT-ID>"
         client_secret: "<YOUR-CLIENT-SECRET>"
         poll_interval: 60  # Optional
   ```

::EndTabs

#### Configure a custom email address suffix

You can set a custom suffix in your project's Service Desk settings.

A suffix can contain only lowercase letters (`a-z`), numbers (`0-9`), or underscores (`_`).

When configured, the custom suffix creates a new Service Desk email address, consisting of the
`service_desk_email_address` setting and a key of the format: `<project_full_path>-<custom_suffix>`

Prerequisites:

- You must have configured a [custom mailbox](#configure-a-custom-mailbox).

1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find your project.
1. Select **Settings > General**.
1. Expand **Service Desk**.
1. Below **Email address suffix**, enter the suffix to use.
1. Select **Save changes**.

For example, suppose the `mygroup/myproject` project Service Desk settings has the following configured:

- Email address suffix is set to `support`.
- Service Desk email address is configured to `contact+%{key}@example.com`.

The Service Desk email address for this project is: `contact+mygroup-myproject-support@example.com`.
The [incoming email](../../administration/incoming_email.md) address still works.

If you don't configure a custom suffix, the default project identification is used for identifying
the project.

### Configure email ingestion in multi-node environments

A multi-node environment is a setup where GitLab is run across multiple servers
for scalability, fault tolerance, and performance reasons.

GitLab uses a separate process called `mail_room` to ingest new unread emails
from the `incoming_email` and `service_desk_email` mailboxes.

#### Helm chart (Kubernetes)

The [GitLab Helm chart](https://docs.gitlab.com/charts/) is made up of multiple subcharts, and one of them is
the [Mailroom subchart](https://docs.gitlab.com/charts/charts/gitlab/mailroom/index.html). Configure the
[common settings for `incoming_email`](https://docs.gitlab.com/charts/installation/command-line-options.html#incoming-email-configuration)
and the [common settings for `service_desk_email`](https://docs.gitlab.com/charts/installation/command-line-options.html#service-desk-email-configuration).

#### Linux package (Omnibus)

In multi-node Linux package installation environments, run `mail_room` only on one node. Run it either on a single
`rails` node (for example, `application_role`)
or completely separately.

##### Set up all nodes

1. Add basic configuration for `incoming_email` and `service_desk_email` on every node
   to render email addresses in the web UI and in generated emails.

   Find the `incoming_email` or `service_desk_email` section in `/etc/gitlab/gitlab.rb`:

   ::Tabs

   :::TabTitle `incoming_email`

   ```ruby
   gitlab_rails['incoming_email_enabled'] = true
   gitlab_rails['incoming_email_address'] = "incoming+%{key}@example.com"
   ```

   :::TabTitle `service_desk_email`

   ```ruby
   gitlab_rails['service_desk_email_enabled'] = true
   gitlab_rails['service_desk_email_address'] = "project_contact+%{key}@example.com"
   ```

   ::EndTabs

1. GitLab offers two methods to transport emails from `mail_room` to the GitLab
application. You can configure the `delivery_method` for each email setting individually:
   1. Recommended: `webhook` (default in GitLab 15.3 and later) sends the email payload via an API POST request to your GitLab
      application. It uses a shared token to authenticate. If you choose this method,
      make sure the `mail_room` process can access the API endpoint and distribute the shared
      token across all application nodes.

      ::Tabs

      :::TabTitle `incoming_email`

      ```ruby
      gitlab_rails['incoming_email_delivery_method'] = "webhook"

      # The URL that mail_room can contact. You can also use an internal URL or IP,
      # just make sure mail_room can access the GitLab API via that address.
      # Do not end with "/".
      gitlab_rails['incoming_email_gitlab_url'] = "https://gitlab.example.com"

      # The shared secret file that should contain a random token. Make sure it's the same on every node.
      gitlab_rails['incoming_email_secret_file'] = ".gitlab_mailroom_secret"
      ```

      :::TabTitle `service_desk_email`

      ```ruby
      gitlab_rails['service_desk_email_delivery_method'] = "webhook"

      # The URL that mail_room can contact. You can also use an internal URL or IP,
      # just make sure mail_room can access the GitLab API via that address.
      # Do not end with "/".

      gitlab_rails['service_desk_email_gitlab_url'] = "https://gitlab.example.com"

      # The shared secret file that should contain a random token. Make sure it's the same on every node.
      gitlab_rails['service_desk_email_secret_file'] = ".gitlab_mailroom_secret"
      ```

      ::EndTabs

   1. [Deprecated in GitLab 16.0 and planned for removal in 17.0)](../../update/deprecations.md#sidekiq-delivery-method-for-incoming_email-and-service_desk_email-is-deprecated):
      If you experience issues with the `webhook` setup, use `sidekiq` to deliver the email payload directly to GitLab Sidekiq using Redis.

      ::Tabs

      :::TabTitle `incoming_email`

      ```ruby
      # It uses the Redis configuration to directly add Sidekiq jobs
      gitlab_rails['incoming_email_delivery_method'] = "sidekiq"
      ```

      :::TabTitle `service_desk_email`

      ```ruby
      # It uses the Redis configuration to directly add Sidekiq jobs
      gitlab_rails['service_desk_email_delivery_method'] = "sidekiq"
      ```

      ::EndTabs

1. Disable `mail_room` on all nodes that should not run email ingestion. For example, in `/etc/gitlab/gitlab.rb`:

   ```ruby
   mailroom['enabled'] = false
   ```

1. [Reconfigure GitLab](../../administration/restart_gitlab.md) for the changes to take effect.

##### Set up a single email ingestion node

After setting up all nodes and disabling the `mail_room` process, enable `mail_room` on a single node.
This node polls the mailboxes for `incoming_email` and `service_desk_email` on a regular basis and
move new unread emails to GitLab.

1. Choose an existing node that additionally handles email ingestion.
1. Add [full configuration and credentials](../../administration/incoming_email.md#configuration-examples)
   for `incoming_email` and `service_desk_email`.
1. Enable `mail_room` on this node. For example, in `/etc/gitlab/gitlab.rb`:

   ```ruby
   mailroom['enabled'] = true
   ```

1. [Reconfigure GitLab](../../administration/restart_gitlab.md) on this node for the changes to take effect.

## Use Service Desk

You can use Service Desk to [create an issue](#as-an-end-user-issue-creator) or [respond to one](#as-a-responder-to-the-issue).
In these issues, you can also see our friendly neighborhood [Support Bot](#support-bot-user).

### View Service Desk email address

To check what the Service Desk email address is for your project:

1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find your project.
1. Select **Monitor > Service Desk**.

The email address is available at the top of the issue list.

### As an end user (issue creator)

> Support for additional email headers [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/346600) in GitLab 14.6. In earlier versions, the Service Desk email address had to be in the "To" field.

To create a Service Desk issue, an end user does not need to know anything about
the GitLab instance. They just send an email to the address they are given, and
receive an email back confirming receipt:

![Service Desk enabled](img/service_desk_confirmation_email.png)

This also gives the end user an option to unsubscribe.

If they don't choose to unsubscribe, then any new comments added to the issue
are sent as emails:

![Service Desk reply email](img/service_desk_reply.png)

Any responses they send via email are displayed in the issue itself.

For information about headers used for treating email, see
[the incoming email documentation](../../administration/incoming_email.md#accepted-headers).

### As a responder to the issue

For responders to the issue, everything works just like other GitLab issues.
GitLab displays a familiar-looking issue tracker where responders can see
issues created through customer support requests, and filter or interact with them.

![Service Desk Issue tracker](img/service_desk_issue_tracker.png)

Messages from the end user are shown as coming from the special
[Support Bot user](../../subscriptions/self_managed/index.md#billable-users).
You can read and write comments as you usually do in GitLab:

![Service Desk issue thread](img/service_desk_thread.png)

- The project's visibility (private, internal, public) does not affect Service Desk.
- The path to the project, including its group or namespace, is shown in emails.

#### View Service Desk issues

Prerequisites:

- You must have at least the Reporter role for the project.

To view Service Desk issues:

1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find your project.
1. Select **Monitor > Service Desk**.

### Email contents and formatting

#### Special HTML formatting in HTML emails

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/109811) in GitLab 15.9 [with a flag](../../administration/feature_flags.md) named `service_desk_html_to_text_email_handler`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/116809) in GitLab 15.11. Feature flag `service_desk_html_to_text_email_handler` removed.

HTML emails show HTML formatting, such as:

- Tables
- Blockquotes
- Images
- Collapsible sections

#### Files attached to comments

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/11733) in GitLab 15.8 [with a flag](../../administration/feature_flags.md) named `service_desk_new_note_email_native_attachments`. Disabled by default.
> - [Enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/386860) in GitLab 15.10.

FLAG:
On self-managed GitLab, by default this feature is available. To hide the feature per project or for your entire instance, ask an administrator to [disable the feature flag](../../administration/feature_flags.md) named `service_desk_new_note_email_native_attachments`.
On GitLab.com, this feature is available.

If a comment contains any attachments and their total size is less than or equal to 10 MB, these
attachments are sent as part of the email. In other cases, the email contains links to the attachments.

In GitLab 15.9 and earlier, uploads to a comment are sent as links in the email.

## Privacy considerations

> [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/108901) the minimum required role to view the creator's and participant's email in GitLab 15.9.

Service Desk issues are [confidential](issues/confidential_issues.md), so they are
only visible to project members. The project owner can
[make an issue public](issues/confidential_issues.md#in-an-existing-issue).
When a Service Desk issue becomes public, the issue creator's and participants' email addresses are
visible to signed-in users with at least the Reporter role for the project.

In GitLab 15.8 and earlier, when a Service Desk issue becomes public, the issue creator's email
address is disclosed to everyone who can view the project.

Anyone in your project can use the Service Desk email address to create an issue in this project, **regardless
of their role** in the project.

The unique internal email address is visible to project members at least
the Reporter role in your GitLab instance.
An external user (issue creator) cannot see the internal email address
displayed in the information note.

### Moving a Service Desk issue

> [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/372246) in GitLab 15.7: customers continue receiving notifications when a Service Desk issue is moved.

You can move a Service Desk issue the same way you
[move a regular issue](issues/managing_issues.md#move-an-issue) in GitLab.

If a Service Desk issue is moved to a different project with Service Desk enabled,
the customer who created the issue continues to receive email notifications.
Because a moved issue is first closed, then copied, the customer is considered to be a participant
in both issues. They continue to receive any notifications in the old issue and the new one.

## Troubleshooting Service Desk

### Emails to Service Desk do not create issues

Your emails might be ignored because they contain one of the
[email headers that GitLab ignores](../../administration/incoming_email.md#rejected-headers).
