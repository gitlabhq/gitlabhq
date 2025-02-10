---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Configure Service Desk
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed

By default, Service Desk is active in new projects.
If it's not active, you can do it in the project's settings.

Prerequisites:

- You must have at least the Maintainer role for the project.
- On GitLab Self-Managed, you must [set up incoming email](../../../administration/incoming_email.md#set-it-up)
  for the GitLab instance. You should use
  [email sub-addressing](../../../administration/incoming_email.md#email-sub-addressing),
  but you can also use [catch-all mailboxes](../../../administration/incoming_email.md#catch-all-mailbox).
  To do this, you must have administrator access.
- You must have enabled [issue](../settings/_index.md#configure-project-features-and-permissions)
  tracker for the project.

To enable Service Desk in your project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Service Desk**.
1. Turn on the **Activate Service Desk** toggle.
1. Optional. Complete the fields.
   - [Add a suffix](#configure-a-suffix-for-service-desk-alias-email) to your Service Desk email address.
   - If the list below **Template to append to all Service Desk issues** is empty, create a
     [description template](../description_templates.md) in your repository.
1. Select **Save changes**.

Service Desk is now enabled for this project.
If anyone sends an email to the address available below **Email address to use for Service Desk**,
GitLab creates a confidential issue with the email's content.

## Service Desk glossary

This glossary provides definitions for terms related to Service Desk.

| Term                                             | Definition |
|--------------------------------------------------|------------|
| [External participant](external_participants.md) | Users without a GitLab account that can interact with an issue or Service Desk ticket only by email. |
| Requester                                        | External participant that created the Service Desk ticket or was added as requester using the [`/convert_to_ticket` quick action](using_service_desk.md#create-a-service-desk-ticket-in-gitlab-ui). |

## Improve your project's security

To improve your Service Desk project's security, you should:

- Put the Service Desk email address behind an alias on your email system so you can change it later.
- [Enable Akismet](../../../integration/akismet.md) on your GitLab instance to add spam checking to this service.
  Unblocked email spam can result in many spam issues being created.

## Customize emails sent to external participants

> - `UNSUBSCRIBE_URL`, `SYSTEM_HEADER`, `SYSTEM_FOOTER`, and `ADDITIONAL_TEXT` placeholders [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/285512) in GitLab 15.9.
> - `%{ISSUE_DESCRIPTION}` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/223751) in GitLab 16.0.
> - `%{ISSUE_URL}` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/408793) in GitLab 16.1.

An email is sent to external participants when:

- A requester submits a new ticket by emailing Service Desk.
- An external participant is added to a Service Desk ticket.
- A new public comment is added on a Service Desk ticket.
  - Editing a comment does not trigger a new email to be sent.

You can customize the body of these email messages with Service Desk email templates. The templates
can include [GitLab Flavored Markdown](../../markdown.md) and [some HTML tags](../../markdown.md#inline-html).
For example, you can format the emails to include a header and footer in accordance with your
organization's brand guidelines. You can also include the following placeholders to display dynamic
content specific to the Service Desk ticket or your GitLab instance.

| Placeholder            | `thank_you.md` and `new_participant` | `new_note.md`          | Description |
|------------------------|--------------------------------------|------------------------|-------------|
| `%{ISSUE_ID}`          | **{check-circle}** Yes               | **{check-circle}** Yes | Ticket IID. |
| `%{ISSUE_PATH}`        | **{check-circle}** Yes               | **{check-circle}** Yes | Project path appended with the ticket IID. |
| `%{ISSUE_URL}`         | **{check-circle}** Yes               | **{check-circle}** Yes | URL of the ticket. External participants can only view the ticket if the project is public and ticket is not confidential (Service Desk tickets are confidential by default). |
| `%{ISSUE_DESCRIPTION}` | **{check-circle}** Yes               | **{check-circle}** Yes | Ticket description. If a user has edited the description, it may contain sensitive information that is not intended to be delivered to external participants. Use this placeholder with care and ideally only if you never modify descriptions or your team is aware of the template design. |
| `%{UNSUBSCRIBE_URL}`   | **{check-circle}** Yes               | **{check-circle}** Yes | Unsubscribe URL. Learn how to [unsubscribe as an external participant](external_participants.md#unsubscribing-from-notification-emails) and [use unsubscribe headers in notification emails from GitLab](../../profile/notifications.md#using-an-email-client-or-other-software). |
| `%{NOTE_TEXT}`         | **{dotted-circle}** No               | **{check-circle}** Yes | The new comment added to the ticket by a user. Take care to include this placeholder in `new_note.md`. Otherwise, the external participants may never see the updates on their Service Desk ticket. |

### Thank you email

When a requester submits an issue through Service Desk, GitLab sends a **thank you email**.
Without additional configuration, GitLab sends the default thank you email.

To create a custom thank you email template:

1. In the `.gitlab/service_desk_templates/` directory of your repository, create a file named `thank_you.md`.
1. Populate the Markdown file with text, [GitLab Flavored Markdown](../../markdown.md),
   [some selected HTML tags](../../markdown.md#inline-html), and placeholders to customize the reply
   to Service Desk requesters.

### New participant email

> - `new_participant` email [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/299261) in GitLab 17.0.

When an [external participant](external_participants.md) is added to the ticket, GitLab sends a **new participant email** to let them know they are part of the conversation.
Without additional configuration, GitLab sends the default new participant email.

To create a custom new participant email template:

1. In the `.gitlab/service_desk_templates/` directory of your repository, create a file named `new_participant.md`.
1. Populate the Markdown file with text, [GitLab Flavored Markdown](../../markdown.md),
   [some selected HTML tags](../../markdown.md#inline-html), and placeholders to customize the reply
   to Service Desk requesters.

### New note email

When a Service Desk ticket has a new public comment, GitLab sends a **new note email**.
Without additional configuration, GitLab sends the content of the comment.

To keep your emails on brand, you can create a custom new note email template. To do so:

1. In the `.gitlab/service_desk_templates/` directory in your repository, create a file named `new_note.md`.
1. Populate the Markdown file with text, [GitLab Flavored Markdown](../../markdown.md),
   [some selected HTML tags](../../markdown.md#inline-html), and placeholders to customize the new note
   email. Be sure to include the `%{NOTE_TEXT}` in the template to make sure the email recipient can
   read the contents of the comment.

### Instance-wide email header, footer, and additional text

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/344819) in GitLab 15.9.

Instance administrators can add a header, footer or additional text to the GitLab instance and apply
them to all emails sent from GitLab. If you're using a custom `thank_you.md`, `new_participant` or `new_note.md`, to include
this content, add `%{SYSTEM_HEADER}`, `%{SYSTEM_FOOTER}`, or `%{ADDITIONAL_TEXT}` to your templates.

For more information, see [System header and footer messages](../../../administration/appearance.md#add-system-header-and-footer-messages) and [custom additional text](../../../administration/settings/email.md#custom-additional-text).

## Use a custom template for Service Desk tickets

You can select one [description template](../description_templates.md#create-an-issue-template)
**per project** to be appended to every new Service Desk ticket's description.

You can set description templates at various levels:

- The entire [instance](../description_templates.md#set-instance-level-description-templates).
- A specific [group or subgroup](../description_templates.md#set-group-level-description-templates).
- A specific [project](../description_templates.md#set-a-default-template-for-merge-requests-and-issues).

The templates are inherited. For example, in a project, you can also access templates set for the instance, or the project's parent groups.

Prerequisites:

- You must have [created a description template](../description_templates.md#create-an-issue-template).

To use a custom description template with Service Desk:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Service Desk**.
1. From the dropdown list **Template to append to all Service Desk issues**, search or select your template.

## Support Bot user

Behind the scenes, Service Desk works by the special Support Bot user creating issues.
This user isn't a [billable user](../../../subscriptions/self_managed/_index.md#billable-users),
so it does not count toward the license limit count.

In GitLab 16.0 and earlier, comments generated from Service Desk emails show `GitLab Support Bot`
as the author. In [GitLab 16.1 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/226995),
these comments show the email of the user who sent the email.
This feature only applies to comments made in GitLab 16.1 and later.

### Change the Support Bot's display name

You can change the display name of the Support Bot user. Emails sent from Service Desk have
this name in the `From` header. The default display name is `GitLab Support Bot`.

To edit the custom email display name:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Service Desk**.
1. Below **Email display name**, enter a new name.
1. Select **Save changes**.

## Default ticket visibility

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/33091) in GitLab 17.2.

New tickets are confidential by default, so only project members with at least the Reporter role
can view them.

In private and internal projects, you can configure GitLab so that new tickets are not confidential by default, and any project member can view them.

In public projects, this setting is not available because new tickets are always confidential by default.

Prerequisites:

- You must have at least the Maintainer role for the project.

To disable this setting:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Service Desk**.
1. Clear the **New tickets are confidential by default** checkbox.
1. Select **Save changes**.

## Reopen issues when an external participant comments

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/8549) in GitLab 16.7

You can configure GitLab to reopen closed issues when an external participant adds
a new comment on an issue by email. This also adds an internal comment that mentions
the assignees of the issue and creates to-do items for them.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For a walkthrough, see [a short showcase video](https://youtu.be/163wDM1e43o).
<!-- Video published on 2023-12-12 -->

Prerequisites:

- You must have at least the Maintainer role for the project.

To enable this setting:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Service Desk**.
1. Select the **Reopen issues on a new note from an external participant** checkbox.
1. Select **Save changes**.

## Custom email address

DETAILS:
**Status**: Beta

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/329990) in GitLab 16.3 [with a flag](../../../administration/feature_flags.md) named `service_desk_custom_email`. Disabled by default.
> - [Enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/387003) in GitLab 16.4.
> - Ability to select the SMTP authentication method [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/429680) in GitLab 16.6.
> - [Feature flag `service_desk_custom_email` removed](https://gitlab.com/gitlab-org/gitlab/-/issues/387003) in GitLab 16.7.
> - Local network allowed for SMTP host on GitLab Self-Managed [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/435206) in GitLab 16.7.

Configure a custom email address to show as the sender of your support communication.
Maintain brand identity and instill confidence among support requesters with a domain they recognize.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [a short showcase video](https://youtu.be/_moD5U3xcQs).
<!-- Video published on 2023-09-12 -->

This feature is in [beta](../../../policy/development_stages_support.md#beta).
A beta feature is not production-ready, but is unlikely to change drastically
before it's released. We encourage users to try beta features and provide feedback
in [the feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/416637).

### Prerequisites

You can use one custom email address for Service Desk per project and it must be unique across the instance.

The custom email address you want to use must meet all of the following requirements:

- You can set up email forwarding.
- Forwarded emails preserve the original `From` header.
- Your service provider must support sub-addressing. An email address consists of a local part (everything before `@`) and a
  domain part.

  With email sub-addressing you can create unique variations of an email address by adding a `+` symbol followed
  by any text to the local part. Given the email address `support@example.com`, check whether sub-addressing is supported by
  sending an email to `support+1@example.com`. This email should appear in your mailbox.
- You have SMTP credentials (ideally, you should use an app password).
  The username and password are stored in the database using the Advanced Encryption Standard (AES)
  with a 256-bit key.
- The **SMTP host** must be resolvable from the network of your GitLab instance (on GitLab Self-Managed)
  or the public internet (on GitLab.com).
- You must have at least the Maintainer role for the project.
- Service Desk must be configured for the project.

### Configure a custom email address

Configure and verify a custom email address when you want to send Service Desk emails using your own email address.

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Service Desk** and find the **Configure a custom email address** section.
1. Note the presented Service Desk address of this project, and with your email provider
   (for example, Gmail), set up email forwarding from the custom email address to the
   Service Desk address.
1. Back in GitLab, complete the fields.
1. Select **Save & test connection**.

The configuration has been saved and the verification of the custom email address is triggered.

#### Verification

1. After completing the configuration, all project owners and the administrator that saved the custom email configuration receive a notification email.
1. A verification email is sent using the provided SMTP credentials to the custom email address (with a sub-addressing part).
   The email contains a verification token. When email forwarding is set up correctly and all prerequisites are met,
   the email is forwarded to your Service Desk address and ingested by GitLab. GitLab checks the following conditions:
   1. GitLab can send an email using the SMTP credentials.
   1. Sub-addressing is supported (with the `+verify` sub-addressing part).
   1. `From` header is preserved after forwarding.
   1. Verification token is correct.
   1. Email is received in 30 minutes.

Typically the process takes only a few minutes.

To cancel verification at any time or if it fails, select **Reset custom email**.
The settings page updates accordingly and reflects the current state of the verification.
The SMTP credentials are deleted and you can start the configuration again.

On failure and success all project owners and the user who triggered the verification process receive a
notification email with the verification result.
If the verification failed, the email also contains details of the reason.

If the verification was successful, the custom email address is ready to be used.
You can now enable sending Service Desk emails with the custom email address.

#### Troubleshooting your configuration

When configuring a custom email you might encounter the following issues.

##### Invalid credentials

You might get an error that states that invalid credentials were used.

This occurs when the SMTP server returns that the authentication wasn't successful.

To troubleshoot this:

1. Check your SMTP credentials, especially the username and password.
1. Sometimes GitLab cannot automatically select an authentication method that the SMTP server supports. Either:
   - Try the available authentication methods (**Plain**, **Login** and **CRAM-MD5**).
   - Check which authentication methods your SMTP server supports, using the
     [`swaks` command line tool](https://www.jetmore.org/john/code/swaks/):

     1. Run the following command with your credentials and look for a line that starts with `250-AUTH`:

        ```shell
        swaks --to user@example.com \
              --from support@example.com \
              --auth-user support@example.com \
              --server smtp@example.com:587 \
              -tls-optional \
              --auth-password your-app-password
        ```

     1. Select one of the supported authentication methods in the custom email setup form.

##### Incorrect forwarding target

You might get an error that states that an incorrect forwarding target was used.

This occurs when the verification email was forwarded to a different email address than the
project-specific Service Desk address that's displayed in the custom email configuration form.

You must use the Service Desk address generated from `incoming_email`. Forwarding to the additional
Service Desk alias address generated from `service_desk_email` is not supported because it doesn't support
all reply by email functionalities.

To troubleshoot this:

1. Find the correct email address to forward emails to. Either:
   - Note the address from the verification result email that all project owners and the user that
     triggered the verification process receive.
   - Copy the address from the **Service Desk email address to forward emails to** input in the
     custom email setup form.
1. Forward all emails to the custom email address to the correct target email address.

### Enable or disable the custom email address

After the custom email address has been verified, administrators can enable or disable sending Service Desk emails with the custom email address.

To **enable** the custom email address:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Service Desk**.
1. Turn on the **Enable custom email** toggle.
   Service Desk emails to external participants are sent using the SMTP credentials.

To **disable** the custom email address:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Service Desk**.
1. Turn off the **Enable custom email** toggle.
   Because you set up email forwarding, emails to your custom email address continue to be processed and
   appear as Service Desk Tickets in your project.

   Service Desk emails to external participants are now sent using the GitLab instance's default outgoing
   email configuration.

### Change or remove custom email configuration

To change the custom email configuration you must reset and remove it and configure custom email again.

To reset the configuration at any step in the process, select **Reset custom email**.
The credentials are then removed from the database.

### Custom email reply address

External participants can [reply by email](../../../administration/reply_by_email.md) to Service Desk tickets.
GitLab uses an email reply address with a 32-character reply key that corresponds to the ticket.
When a custom email is configured, GitLab generates the reply address from that email.

### Use Google Workspace with your own domain

Set up a custom email address for Service Desk when using Google Workspace with your own domain.

Prerequisites:

- You already have a Google Workspace account.
- You can create new accounts for your tenant.

To configure a custom Service Desk email address with Google Workspace:

1. [Configure a Google Workspace account](#configure-a-google-workspace-account).
1. [Configure email forwarding in Google Workspace](#configure-email-forwarding-in-google-workspace).
1. [Configure custom email address using a Google Workspace account](#configure-custom-email-address-using-a-google-workspace-account).

#### Configure a Google Workspace account

First, you must create and configure a Google Workspace account.

In Google Workspace:

1. Create a new account for the custom email address you'd like to use (for example, `support@example.com`).
1. Sign in to that account and activate
   [two-factor authentication](https://myaccount.google.com/u/3/signinoptions/two-step-verification).
1. [Create an app password](https://myaccount.google.com/u/3/apppasswords) that you can use as your
   SMTP password.
   Store it in a secure place and remove spaces between the characters.

Next, you must [configure email forwarding in Google Workspace](#configure-email-forwarding-in-google-workspace).

#### Configure email forwarding in Google Workspace

The following steps require moving between GitLab and Google Workspace.

In GitLab:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**
1. Expand **Service Desk**.
1. Note the email address below **Service Desk email address to forward emails to**.

In Google Workspace:

1. Sign in to the custom email account and open the [Forwarding and POP/IMAP](https://mail.google.com/mail/u/0/#settings/fwdandpop) settings page.
1. Select **Add a forwarding address**.
1. Enter the Service Desk address from the custom email form.
1. Select **Next**.
1. Confirm your input and select **Proceed**. Google sends an email to the Service Desk address and
   requires a confirmation code.

In GitLab:

1. Go to **Issues** of the project and wait for a new issue to be created from the confirmation
   email from Google.
1. Open the issue and note the confirmation code.
1. (Optional) Delete the issue.

In Google Workspace:

1. Enter the confirmation code and select **Verify**.
1. Select **Forward a copy of incoming mail to** and make sure the Service Desk address is selected
   from the dropdown list.
1. At the bottom of the page, select **Save Changes**.

Next, [configure custom email address using a Google Workspace account](#configure-custom-email-address-using-a-google-workspace-account)
to use with Service Desk.

#### Configure custom email address using a Google Workspace account

In GitLab:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**
1. Expand **Service Desk** and find the custom email settings.
1. Complete the fields:
   - **Custom email address**: Your custom email address.
   - **SMTP host**: `smtp.gmail.com`.
   - **SMTP port**: `587`.
   - **SMTP username**: Prefilled with the custom email address.
   - **SMTP password**: The app password you previously created for the custom email account.
   - **SMTP authentication method**: Let GitLab select a server-supported method (recommended)
1. Select **Save and test connection**
1. After the [verification process](#verification) you should be able to
   [enable the custom email address](#enable-or-disable-the-custom-email-address).

### Use Microsoft 365 (Exchange online) with your own domain

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/496396) in GitLab 17.5.

Set up a custom email address for Service Desk when using Microsoft 365 (Exchange) with your own domain.

Prerequisites:

- You already have a Microsoft 365 account.
- You can create new accounts for your tenant.

To configure a custom Service Desk email address with Microsoft 365:

1. [Configure a Microsoft 365 account](#configure-a-microsoft-365-account).
1. [Configure email forwarding in Microsoft 365](#configure-email-forwarding-in-microsoft-365).
1. [Configure custom email address using a Microsoft 365 account](#configure-custom-email-address-using-a-microsoft-365-account).

#### Configure a Microsoft 365 account

First, you must create and configure a Microsoft 365 account.
In this guide, use a licensed user for the custom email mailbox.
You can also experiment with other configuration options.

In [Microsoft 365 admin center](https://admin.microsoft.com/Adminportal/Home#/homepage):

1. Create a new account for the custom email address you'd like to use (for example, `support@example.com`).
   1. Expand the **Users** section and select **Active users** from the menu.
   1. Select **Add a user** and follow the instructions on the screen.
1. In Microsoft Entra (previously named Active Directory), enable two-factor authentication for the account.
1. [Allow users to create app passwords](https://learn.microsoft.com/en-us/entra/identity/authentication/howto-mfa-app-passwords).
1. Enable **Authenticated SMTP** for the account.
   1. Select the account from the list.
   1. In the drawer select **Mail**.
   1. Below **Email apps** select **Manage email apps**.
   1. Check **Authenticated SMTP** and select **Save changes**.
1. Depending on your overall Exchange online configuration you might need to configure the following:
   1. Use Azure Cloud Shell to allow SMTP client authentication:

      ```powershell
      Set-TransportConfig -SmtpClientAuthenticationDisabled $false
      ```

   1. Use Azure Cloud Shell to allow
      [legacy TLS clients using SMTP AUTH](https://learn.microsoft.com/en-us/exchange/clients-and-mobile-in-exchange-online/opt-in-exchange-online-endpoint-for-legacy-tls-using-smtp-auth):

      ```powershell
      Set-TransportConfig -AllowLegacyTLSClients $true
      ```

   1. If you want to forward to an external recipient, please see this guide on how to enable
      [external email forwarding](https://learn.microsoft.com/en-gb/defender-office-365/outbound-spam-policies-external-email-forwarding).
      You might also want to [create an outbound anti-spam policy](https://security.microsoft.com/antispam)
      to allow forwarding to external recipients only for users who need it.
1. Sign in to that account and activate two-factor authentication.
   <!-- vale gitlab_base.SubstitutionWarning = NO -->
   1. From the menu in the upper-right corner, select **View account** and [browse to **Security Info**](https://mysignins.microsoft.com/security-info).
   <!-- vale gitlab_base.SubstitutionWarning = YES -->
   1. Select **Add sign-in method** and select a method that works for you (authenticator app, phone or email).
   1. Follow the instructions on the screen.
<!-- vale gitlab_base.SubstitutionWarning = NO -->
1. On the [**Security Info**](https://mysignins.microsoft.com/security-info) page,
   create an app password that you can use as your SMTP password.
<!-- vale gitlab_base.SubstitutionWarning = YES -->
   1. Select **Add sign-in method** and select **App password** from the dropdown list.
   1. Set a descriptive name for the app password, such as `GitLab SD`.
   1. Select **Next**.
   1. Copy the displayed password and store it in a secure place.
   1. Optional. Ensure you can send emails using SMTP using the [`swaks` command line tool](https://www.jetmore.org/john/code/swaks/).
   1. Run the following command with your credentials and use the app password as the `auth-password`:

      ```shell
      swaks --to your-email@example.com \
            --from custom-email@example.com \
            --auth-user custom-email@example.com \
            --server smtp.office365.com:587 \
            -tls-optional \
            --auth-password <your_app_password>
      ```

Next, you must [configure email forwarding in Microsoft 365](#configure-email-forwarding-in-microsoft-365).

#### Configure email forwarding in Microsoft 365

The following steps require moving between GitLab and Microsoft 365 admin center.

In GitLab:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**
1. Expand **Service Desk**.
1. Note the email address below **Service Desk email address to forward emails to** without the
   sub-address part.

   Emails aren't forwarded if the recipient address contains a sub-address (for example reply
   addresses generated by GitLab) and the forwarding email address contains a sub-address
   (the **Service Desk email address to forward emails to**).

   For example, `incoming+group-project-12346426-issue-@incoming.gitlab.com` becomes `incoming@incoming.gitlab.com`.
   That's okay because Exchange online preserves the custom email address in the `To` header
   after forwarding and GitLab can assign the correct project based on the custom email address.

In [Microsoft 365 admin center](https://admin.microsoft.com/Adminportal/Home#/homepage):

<!-- vale gitlab_base.SubstitutionWarning = NO -->
1. Expand the **Users** section and select **Active users** from the menu.
<!-- vale gitlab_base.SubstitutionWarning = YES -->
1. Select the account you'd like to use for the custom email from the list.
1. In the drawer select **Mail**.
1. Below **Email forwarding** select **Manage email forwarding**.
1. Check **Forward all emails sent to this mailbox**.
1. Enter the Service Desk address from the custom email form in **Forwarding email address** without the sub-address part.
1. Select **Save changes**.

Next, [configure a custom email address using a Microsoft 365 account](#configure-custom-email-address-using-a-microsoft-365-account)
to use with Service Desk.

#### Configure custom email address using a Microsoft 365 account

In GitLab:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**
1. Expand **Service Desk** and find the custom email settings.
1. Complete the fields:
   - **Custom email address**: Your custom email address.
   - **SMTP host**: `smtp.office365.com`.
   - **SMTP port**: `587`.
   - **SMTP username**: Prefilled with the custom email address.
   - **SMTP password**: The app password you previously created for the custom email account.
   - **SMTP authentication method**: Login
1. Select **Save and test connection**
1. After the [verification process](#verification) you should be able to
   [enable the custom email address](#enable-or-disable-the-custom-email-address).

### Known issues

- Some service providers don't allow SMTP connections any more.
  Often you can enable them on a per user basis and create an app password.

## Use an additional Service Desk alias email

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

You can use an additional alias email address for Service Desk for an instance.

To do this, you must configure
a [`service_desk_email`](#configure-service-desk-alias-email) in the instance configuration. You can also configure a
[custom suffix](#configure-a-suffix-for-service-desk-alias-email) that replaces the default `-issue-` portion on the sub-addressing part.

### Configure Service Desk alias email

NOTE:
On GitLab.com a custom mailbox is already configured with `contact-project+%{key}@incoming.gitlab.com` as the email address. You can still configure the
[custom suffix](#configure-a-suffix-for-service-desk-alias-email) in project settings.

Service Desk uses the [incoming email](../../../administration/incoming_email.md)
configuration by default. However, to have a separate email address for Service Desk,
configure `service_desk_email` with a [custom suffix](#configure-a-suffix-for-service-desk-alias-email)
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
[incoming email](../../../administration/incoming_email.md#set-it-up).

#### Use encrypted credentials

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/108279) in GitLab 15.9.

Instead of having the Service Desk email credentials stored in plaintext in the configuration files, you can optionally
use an encrypted file for the incoming email credentials.

Prerequisites:

- To use encrypted credentials, you must first enable the
  [encrypted configuration](../../../administration/encrypted_configuration.md).

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

#### Microsoft Graph

> - [Introduced for self-compiled (source) installs](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/116494) in GitLab 15.11.

`service_desk_email` can be configured to read Microsoft Exchange Online mailboxes with the Microsoft
Graph API instead of IMAP. Set up an OAuth 2.0 application for Microsoft Graph
[the same way as for incoming email](../../../administration/incoming_email.md#microsoft-graph).

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

### Configure a suffix for Service Desk alias email

You can set a custom suffix in your project's Service Desk settings.

A suffix can contain only lowercase letters (`a-z`), numbers (`0-9`), or underscores (`_`).

When configured, the custom suffix creates a new Service Desk email address, consisting of the
`service_desk_email_address` setting and a key of the format: `<project_full_path>-<custom_suffix>`

Prerequisites:

- You must have configured a [Service Desk alias email](#configure-service-desk-alias-email).

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Service Desk**.
1. Below **Email address suffix**, enter the suffix to use.
1. Select **Save changes**.

For example, suppose the `mygroup/myproject` project Service Desk settings has the following configured:

- Email address suffix is set to `support`.
- Service Desk email address is configured to `contact+%{key}@example.com`.

The Service Desk email address for this project is: `contact+mygroup-myproject-support@example.com`.
The [incoming email](../../../administration/incoming_email.md) address still works.

If you don't configure a custom suffix, the default project identification is used for identifying
the project.

## Configure email ingestion in multi-node environments

A multi-node environment is a setup where GitLab is run across multiple servers
for scalability, fault tolerance, and performance reasons.

GitLab uses a separate process called `mail_room` to ingest new unread emails
from the `incoming_email` and `service_desk_email` mailboxes.

### Helm chart (Kubernetes)

The [GitLab Helm chart](https://docs.gitlab.com/charts/) is made up of multiple subcharts, and one of them is
the [Mailroom subchart](https://docs.gitlab.com/charts/charts/gitlab/mailroom/index.html). Configure the
[common settings for `incoming_email`](https://docs.gitlab.com/charts/installation/command-line-options.html#incoming-email-configuration)
and the [common settings for `service_desk_email`](https://docs.gitlab.com/charts/installation/command-line-options.html#service-desk-email-configuration).

### Linux package (Omnibus)

In multi-node Linux package installation environments, run `mail_room` only on one node. Run it either on a single
`rails` node (for example, `application_role`)
or completely separately.

#### Set up all nodes

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
   1. Recommended: `webhook` (default in GitLab 15.3 and later) sends the email payload with an API POST request to your GitLab
      application. It uses a shared token to authenticate. If you choose this method,
      make sure the `mail_room` process can access the API endpoint and distribute the shared
      token across all application nodes.

      ::Tabs

      :::TabTitle `incoming_email`

      ```ruby
      gitlab_rails['incoming_email_delivery_method'] = "webhook"

      # The URL that mail_room can contact. You can also use an internal URL or IP,
      # just make sure mail_room can access the GitLab API with that address.
      # Do not end with "/".
      gitlab_rails['incoming_email_gitlab_url'] = "https://gitlab.example.com"

      # The shared secret file that should contain a random token. Make sure it's the same on every node.
      gitlab_rails['incoming_email_secret_file'] = ".gitlab_mailroom_secret"
      ```

      :::TabTitle `service_desk_email`

      ```ruby
      gitlab_rails['service_desk_email_delivery_method'] = "webhook"

      # The URL that mail_room can contact. You can also use an internal URL or IP,
      # just make sure mail_room can access the GitLab API with that address.
      # Do not end with "/".

      gitlab_rails['service_desk_email_gitlab_url'] = "https://gitlab.example.com"

      # The shared secret file that should contain a random token. Make sure it's the same on every node.
      gitlab_rails['service_desk_email_secret_file'] = ".gitlab_mailroom_secret"
      ```

      ::EndTabs

   1. [Deprecated in GitLab 16.0 and planned for removal in 19.0)](../../../update/deprecations.md#sidekiq-delivery-method-for-incoming_email-and-service_desk_email-is-deprecated):
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
   mailroom['enable'] = false
   ```

1. [Reconfigure GitLab](../../../administration/restart_gitlab.md) for the changes to take effect.

#### Set up a single email ingestion node

After setting up all nodes and disabling the `mail_room` process, enable `mail_room` on a single node.
This node polls the mailboxes for `incoming_email` and `service_desk_email` on a regular basis and
move new unread emails to GitLab.

1. Choose an existing node that additionally handles email ingestion.
1. Add [full configuration and credentials](../../../administration/incoming_email.md#configuration-examples)
   for `incoming_email` and `service_desk_email`.
1. Enable `mail_room` on this node. For example, in `/etc/gitlab/gitlab.rb`:

   ```ruby
   mailroom['enable'] = true
   ```

1. [Reconfigure GitLab](../../../administration/restart_gitlab.md) on this node for the changes to take effect.
