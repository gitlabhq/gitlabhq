---
stage: Manage
group: Integrations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Jira DVCS connector **(FREE)**

Use the Jira DVCS (distributed version control system) connector if you self-host
your Jira instance, and you want to sync information
between GitLab and Jira. If you use Jira Cloud, you should use the
[GitLab.com for Jira Cloud app](connect-app.md) unless you specifically need the
DVCS connector.

When you configure the Jira DVCS connector, make sure your GitLab and Jira instances
are accessible.

- **Self-managed GitLab**: Your GitLab instance must be accessible by Jira.
- **Jira Server**: Your network must allow access to your instance.
- **Jira Cloud**: Your instance must be accessible through the internet.

NOTE:
When using GitLab 15.0 and later (including GitLab.com) with Jira Server, you might experience a [session token bug in Jira](https://jira.atlassian.com/browse/JSWSERVER-21389). As a workaround, ensure Jira Server is version 9.1.0 and later or 8.20.11 and later.

## Smart Commits

When connecting GitLab with Jira with DVCS, you can process your Jira issues using
special commands, called
[Smart Commits](https://support.atlassian.com/jira-software-cloud/docs/process-issues-with-smart-commits/),
in your commit messages. With Smart Commits, you can:

- Comment on issues.
- Record time-tracking information against issues.
- Transition issues to any status defined in the Jira project's workflow.

Commands must be in the first line of the commit message. The
[Jira Software documentation](https://support.atlassian.com/jira-software-cloud/docs/process-issues-with-smart-commits/)
contains more information about how Smart Commits work, and what commands are available
for your use.

For Smart Commits to work, the committing user on GitLab must have a corresponding
user on Jira with the same email address or username.

### Smart Commit syntax

Smart Commits should follow the pattern of:

```plaintext
<ISSUE_KEY> <ignored text> #<command> <optional command parameters>
```

Some examples:

- Add a comment to a Jira issue: `KEY-123 fixes a bug #comment Bug is fixed.`
- Record time tracking: `KEY-123 #time 2w 4d 10h 52m Tracking work time.`
- Close an issue: `KEY-123 #close Closing issue`

A Smart Commit message must not span more than one line (no carriage returns) but
you can still perform multiple actions in a single commit. For example:

- Add time tracking, add a comment, and transition to **Closed**:

  ```plaintext
  KEY-123 #time 2d 5h #comment Task completed ahead of schedule #close
  ```

- Add a comment, transition to **In-progress**, and add time tracking:

  ```plaintext
  KEY-123 #comment started working on the issue #in-progress #time 12d 5h
  ```

## Configure a GitLab application for DVCS

For projects in a single group we recommend you create a [group application](../oauth_provider.md#create-a-group-owned-application).
For projects across multiple groups we recommend you create and use a `jira` user in GitLab, and use the account
only for integration work. A separate account ensures regular account
maintenance does not affect your integration. If a `jira` user or group application is not feasible,
you can set up this integration as an [instance-wide application](../oauth_provider.md#create-an-instance-wide-application)
or with a [user owned application](../oauth_provider.md#create-a-user-owned-application) instead.

1. Navigate to the [appropriate **Applications** section](../oauth_provider.md).
1. In the **Name** field, enter a descriptive name for the integration, such as `Jira`.
1. In the **Redirect URI** field, enter the URI appropriate for your version of GitLab,
   replacing `<gitlab.example.com>` with your GitLab instance domain:
   - *For GitLab versions 13.0 and later* **and** *Jira versions 8.14 and later,* use the
     generated `Redirect URL` from
     [Linking GitLab accounts with Jira](https://confluence.atlassian.com/adminjiraserver/linking-gitlab-accounts-1027142272.html).
   - *For GitLab versions 13.0 and later* **and** *Jira Cloud,* use `https://<gitlab.example.com>/login/oauth/callback`.
   - *For GitLab versions 11.3 and later* **and** *Jira versions 8.13 and earlier,* use `https://<gitlab.example.com>/login/oauth/callback`.
     If you use GitLab.com, the URL is `https://gitlab.com/login/oauth/callback`.
   - *For GitLab versions 11.2 and earlier,* use
     `https://<gitlab.example.com>/-/jira/login/oauth/callback`.

1. For **Scopes**, select `api` and clear any other checkboxes.
   - The DVCS connector requires a _write-enabled_ `api` scope to automatically create and manage required webhooks.
1. Select **Submit**.
1. Copy the **Application ID** and **Secret** values.
   You need them to configure Jira.

## Configure Jira for DVCS

Configure this connection when you want to import all GitLab commits and branches,
for the groups you specify, into Jira. This import takes a few minutes and, after
it completes, refreshes every 60 minutes:

1. Complete the [GitLab configuration](#configure-a-gitlab-application-for-dvcs).
1. Go to your DVCS accounts:
   - *For Jira Server,* select **Settings (gear) > Applications > DVCS accounts**.
   - *For Jira Cloud,* select **Settings (gear) > Products > DVCS accounts**.
1. To create a new integration, select the appropriate value for **Host**:
   - *For Jira versions 8.14 and later:* Select **GitLab** or
     **GitLab Self-Managed**.
   - *For Jira Cloud or Jira versions 8.13 and earlier:* Select **GitHub Enterprise**.
1. For **Team or User Account**, enter either:
   - *For Jira versions 8.14 and later:*
      - The relative path of a top-level GitLab group that
        [the GitLab user](#configure-a-gitlab-application-for-dvcs) has access to.
   - *For Jira Cloud or Jira versions 8.13 and earlier:*
      - The relative path of a top-level GitLab group that
        [the GitLab user](#configure-a-gitlab-application-for-dvcs) has access to.
      - The relative path of your personal namespace.

1. In the **Host URL** field, enter the URI appropriate for your version of GitLab,
   replacing `<gitlab.example.com>` with your GitLab instance domain:
   - *For GitLab versions 11.3 and later,* use `https://<gitlab.example.com>`.
   - *For GitLab versions 11.2 and earlier,* use
     `https://<gitlab.example.com>/-/jira`.

1. For **Client ID**, use the **Application ID** value from the previous section.
1. For **Client Secret**, use the **Secret** value from the previous section.
1. Ensure that the rest of the checkboxes are selected.
1. To create the DVCS account, select **Add** and then **Continue**.
1. Jira redirects to GitLab where you have to confirm the authorization.
   GitLab then redirects back to Jira where the synced
   projects should display in the new account.

To connect additional GitLab projects from other GitLab top-level groups or
personal namespaces, repeat the previous steps with additional Jira DVCS accounts.

After you configure the integration, read more about [how to test and use it](development_panel.md).

## Refresh data imported to Jira

Jira imports the commits and branches every 60 minutes for your projects. You
can refresh the data manually from the Jira interface:

1. Sign in to your Jira instance as the user you configured the integration with.
1. Go to **Settings (gear) > Applications**.
1. Select **DVCS accounts**.
1. In the table, for the repository you want to refresh, in the **Last Activity**
   column, select the icon:
   ![Refresh GitLab information in Jira](img/jira_dev_panel_manual_refresh.png)

## Troubleshoot your DVCS connection

Refer to the items in this section if you're having problems with your DVCS connector.

### Jira cannot access GitLab server

If you complete the **Add New Account** form, authorize access, and you receive
this error, Jira and GitLab cannot connect. No other error messages
appear in any logs:

```plaintext
Error obtaining access token. Cannot access https://gitlab.example.com from Jira.
```

### SSL and TLS problems

Problems with SSL and TLS can cause this error message:

```plaintext
Error obtaining access token. Cannot access https://gitlab.example.com from Jira.
```

- The [GitLab Jira integration](index.md) requires
  GitLab to connect to Jira. Any TLS issues that arise from a private certificate
  authority or self-signed certificate are resolved
  [on the GitLab server](https://docs.gitlab.com/omnibus/settings/ssl.html#install-custom-public-certificates),
  as GitLab is the TLS client.
- The Jira Development panel integration requires Jira to connect to GitLab, which
  causes Jira to be the TLS client. If your GitLab server's certificate is not
  issued by a public certificate authority, add the appropriate certificate
  (such as your organization's root certificate) to the Java Truststore on Jira's server.

Refer to Atlassian's documentation and Atlassian Support for assistance setting
up Jira correctly:

- [Add a certificate](https://confluence.atlassian.com/kb/how-to-import-a-public-ssl-certificate-into-a-jvm-867025849.html)
  to the trust store.
  - The simplest approach is [`keytool`](https://docs.oracle.com/javase/8/docs/technotes/tools/unix/keytool.html).
  - Add additional roots to Java's default Truststore (`cacerts`) to allow Jira to
    also trust public certificate authorities.
  - If the integration stops working after upgrading Jira's Java runtime, the
    `cacerts` Truststore may have been replaced during the upgrade.

- Troubleshoot connectivity [up to and including TLS handshaking](https://confluence.atlassian.com/kb/unable-to-connect-to-ssl-services-due-to-pkix-path-building-failed-error-779355358.html),
  using the `SSLPoke` Java class.
- Download the class from Atlassian's knowledge base to a directory on Jira's server, such as `/tmp`.
- Use the same Java runtime as Jira.
- Pass all networking-related parameters that Jira is called with, such as proxy
  settings or an alternative root Truststore (`-Djavax.net.ssl.trustStore`):

```shell
${JAVA_HOME}/bin/java -Djavax.net.ssl.trustStore=/var/atlassian/application-data/jira/cacerts -classpath /tmp SSLPoke gitlab.example.com 443
```

The message `Successfully connected` indicates a successful TLS handshake.

If there are problems, the Java TLS library generates errors that you can
look up for more detail.

### Scope error when connecting to Jira using DVCS

```plaintext
The requested scope is invalid, unknown, or malformed.
```

Potential resolutions:

1. Verify that the URL shown in the browser after being redirected from Jira in the
   [Jira DVCS connector setup](#configure-jira-for-dvcs) includes `scope=api` in
   the query string.
1. If `scope=api` is missing from the URL, edit the
   [GitLab account configuration](#configure-a-gitlab-application-for-dvcs). Review
   the **Scopes** field and ensure the `api` checkbox is selected.

### Jira error adding account and no repositories listed

After you complete the **Add New Account** form in Jira and authorize access, you might
encounter these issues:

- An `Error! Failed adding the account: [Error retrieving list of repositories]` error.
- An `Account is already integrated with JIRA` error when you select **Try Again**.
- An account is visible in the DVCS accounts view, but no repositories are listed.

To resolve this issue:

- If you're using GitLab Free, ensure you're using GitLab 13.4 or later.
- If you're using GitLab versions 11.10-12.7, upgrade to GitLab 12.8.10 or later
  to resolve [an identified issue](https://gitlab.com/gitlab-org/gitlab/-/issues/37012).

[Contact GitLab Support](https://about.gitlab.com/support/) if none of these reasons apply.

### `410 : Gone` error when connecting to Jira

When you connect to Jira and synchronize repositories, you may receive a `410 : Gone` error.

This issue occurs when you use the Jira DVCS connector and your integration is configured to use **GitHub Enterprise**.

For more information and possible fixes, see [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/340160).

### Synchronization issues

If Jira displays incorrect information, such as deleted branches, you may have to
resynchronize the information:

1. In Jira, select **Jira Administration > Applications > DVCS accounts**.
1. For the account (group or subgroup), select
   **Refresh repositories** from the **{ellipsis_h}** (ellipsis) menu.
1. For each project, next to the **Last activity** date:
   - To perform a *soft resync*, select the sync icon.
   - To complete a *full sync*, press `Shift` and select the sync icon.

For more information, read
[Atlassian's documentation](https://support.atlassian.com/jira-cloud-administration/docs/integrate-with-development-tools/).

### `Sync Failed` error when refreshing repository data

If you get a `Sync Failed` error in Jira when [refreshing repository data](#refresh-data-imported-to-jira) for specific projects, check your DVCS connector logs. Look for errors that occur when executing requests to API resources in GitLab. For example:

```plaintext
Failed to execute request [https://gitlab.com/api/v4/projects/:id/merge_requests?page=1&per_page=100 GET https://gitlab.com/api/v4/projects/:id/merge_requests?page=1&per_page=100 returned a response status of 403 Forbidden] errors:
{"message":"403 Forbidden"}
```

If you find a `{"message":"403 Forbidden"}` error, it is possible that this specific project has some [GitLab features disabled](../../user/project/settings/index.md#configure-project-visibility-features-and-permissions).
In the example above, the merge requests feature is disabled.

To resolve the issue, enable the relevant feature:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > General**.
1. Expand **Visibility, project features, permissions**.
1. Use the toggles to enable the features as needed.

### Find webhook logs in a DVCS-linked project

To find webhook logs in a DVCS-linked project:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > Webhooks**.
1. Scroll down to **Project Hooks**.
1. Next to the log that points to your Jira instance, select **Edit**.
1. Scroll down to **Recent events**.

If you can't find webhook logs in your project, check your DVCS setup for problems.
