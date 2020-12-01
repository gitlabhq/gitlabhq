---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# GitLab Jira Development Panel integration **(CORE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/2381) in [GitLab Premium](https://about.gitlab.com/pricing/) 10.0.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/233149) to [GitLab Core](https://about.gitlab.com/pricing/) in 13.4.

The Jira Development Panel integration allows you to reference Jira issues within GitLab, displaying
activity in the [Development panel](https://support.atlassian.com/jira-software-cloud/docs/view-development-information-for-an-issue/)
in the issue.

It complements the [GitLab Jira integration](../user/project/integrations/jira.md). You may choose
to configure both integrations to take advantage of both sets of features. See a
[feature comparison](../user/project/integrations/jira_integrations.md#feature-comparison).

Depending on your environment, you can enable this integration by either:

- Configuring the Jira DVCS connector.
- Using the GitLab for Jira app in the Atlassian Marketplace.

See the [Configuration](#configuration) section for details.

## Features

| Your mention of Jira issue ID in GitLab context   | Automated effect in Jira issue                                                                         |
|---------------------------------------------------|--------------------------------------------------------------------------------------------------------|
| In a merge request                                | Link to the MR is displayed in Development panel.                                                      |
| In a branch name                                  | Link to the branch is displayed in Development panel.                                                  |
| In a commit message                               | Link to the commit is displayed in Development panel.                                                  |
| In a commit message with Jira Smart Commit format | Displays your custom comment or logged time spent and/or performs specified issue transition on merge. |

With this integration, you can access related GitLab merge requests, branches, and commits directly from a Jira issue, reflecting your work in GitLab. From the Development panel, you can open a detailed view and take actions including creating a new merge request from a branch. For more information, see [Usage](#usage).

This integration connects all GitLab projects to projects in the Jira instance within either:

- A top-level group. A top-level GitLab group is one that does not have any parent group itself. All
  the projects of that top-level group, as well as projects of the top-level group's subgroups nesting
  down, are connected.
- A personal namespace, which then connects the projects in that personal namespace to Jira.

This differs from the [Jira integration](../user/project/integrations/jira.md), where the mapping is between one GitLab project and the entire Jira instance.

## Configuration

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [Agile Management - GitLab-Jira Development Panel Integration](https://www.youtube.com/watch?v=VjVTOmMl85M&feature=youtu.be).

If you're using:

- GitLab.com and Jira Cloud, we recommend you enable this integration by installing the
  [GitLab for Jira app](#gitlab-for-jira-app) from the Atlassian Marketplace, which offers a real-time
  sync between GitLab and Jira.
- Self-managed GitLab, self-managed Jira, or both, configure the integration using
  [Jira's DVCS Connector](#jira-dvcs-configuration), which syncs data hourly.

We recommend that a GitLab group administrator or instance administrator (in the case of
self-managed GitLab) set up the integration to simplify administration.

### Jira DVCS configuration

If you're using GitLab.com and Jira Cloud, we recommend you use the
[GitLab for Jira app](#gitlab-for-jira-app), unless you have a specific need for the DVCS Connector.

When configuring Jira DVCS Connector:

- If you are using self-managed GitLab, make sure your GitLab instance is accessible by Jira.
- If you're connecting to Jira Cloud, ensure your instance is accessible through the internet.
- If you are using Jira Server, make sure your instance is accessible however your network is set up.

#### GitLab account configuration for DVCS

TIP: **Tip:**
To ensure that regular user account maintenance doesn't impact your integration,
create and use a single-purpose `jira` user in GitLab.

1. In GitLab, create a new application to allow Jira to connect with your GitLab account.

   While signed in to the GitLab account that you want Jira to use to connect to GitLab,
   click your profile avatar at the top right, and then click **Settings > Applications**.
   Use the form to create a new application.

   In the **Name** field, enter a descriptive name for the integration, such as `Jira`.

   For the **Redirect URI** field, enter `https://<gitlab.example.com>/login/oauth/callback`,
   replacing `<gitlab.example.com>` with your GitLab instance domain. For example, if you are using GitLab.com,
   this would be `https://gitlab.com/login/oauth/callback`.

   NOTE: **Note:**
   If using a GitLab version earlier than 11.3, the `Redirect URI` must be
   `https://<gitlab.example.com>/-/jira/login/oauth/callback`. If you want Jira
   to have access to all projects, GitLab recommends that an administrator create the
   application.

   ![GitLab application setup](img/jira_dev_panel_gl_setup_1.png)

   - Check **API** in the Scopes section and uncheck any other checkboxes.

1. Click **Save application**. GitLab displays the generated **Application ID**
   and **Secret** values. Copy these values, which you use in Jira.

#### Jira DVCS Connector setup

If you're using GitLab.com and Jira Cloud, we recommend you use the
[GitLab for Jira app](#gitlab-for-jira-app), unless you have a specific need for the DVCS Connector.

1. Ensure you have completed the [GitLab configuration](#gitlab-account-configuration-for-dvcs).
1. If you're using Jira Server, go to **Settings (gear) > Applications > DVCS accounts**.
   If you're using Jira Cloud, go to **Settings (gear) > Products > DVCS accounts**.
1. Click **Link GitHub Enterprise account** to start creating a new integration.
   (We're pretending to be GitHub in this integration, until there's additional platform support in Jira.)
1. Complete the form:

   Select **GitHub Enterprise** for the **Host** field.

   In the **Team or User Account** field, enter the relative path of a top-level GitLab group that you have access to,
   or the relative path of your personal namespace.

   ![Creation of Jira DVCS integration](img/jira_dev_panel_jira_setup_2.png)

   In the **Host URL** field, enter `https://<gitlab.example.com>/`,
   replacing `<gitlab.example.com>` with your GitLab instance domain. For example, if you are using GitLab.com,
   this would be `https://gitlab.com/`.

   NOTE: **Note:**
   If using a GitLab version earlier than 11.3 the **Host URL** value should be `https://<gitlab.example.com>/-/jira`

   For the **Client ID** field, use the **Application ID** value from the previous section.

   For the **Client Secret** field, use the **Secret** value from the previous section.

   Ensure that the rest of the checkboxes are checked.

1. Click **Add** to complete and create the integration.

   Jira takes up to a few minutes to know about (import behind the scenes) all the commits and branches
   for all the projects in the GitLab group you specified in the previous step. These are refreshed
   every 60 minutes.

   In the future, we plan on implementing real-time integration. If you need
   to refresh the data manually, you can do this from the `Applications -> DVCS
   accounts` screen where you initially set up the integration:

   ![Refresh GitLab information in Jira](img/jira_dev_panel_manual_refresh.png)

To connect additional GitLab projects from other GitLab top-level groups (or personal namespaces), repeat the previous
steps with additional Jira DVCS accounts.

Now that the integration is configured, read more about how to test and use it in [Usage](#usage).

#### Troubleshooting your DVCS connection

Refer to the items in this section if you're having problems with your DVCS connector.

##### Jira cannot access GitLab server

```plaintext
Error obtaining access token. Cannot access https://gitlab.example.com from Jira.
```

This error message is generated in Jira, after completing the **Add New Account**
form and authorizing access. It indicates a connectivity issue from Jira to
GitLab. No other error messages appear in any logs.

If there was an issue with SSL/TLS, this error message is generated.

- The [GitLab Jira integration](../user/project/integrations/jira.md) requires GitLab to connect to Jira. Any
  TLS issues that arise from a private certificate authority or self-signed
  certificate [are resolved on the GitLab server](https://docs.gitlab.com/omnibus/settings/ssl.html#other-certificate-authorities),
  as GitLab is the TLS client.
- The Jira Development Panel integration requires Jira to connect to GitLab, which
  causes Jira to be the TLS client. If your GitLab server's certificate is not
  issued by a public certificate authority, the Java truststore on Jira's server
  needs to have the appropriate certificate added to it (such as your organization's
  root certificate).

Refer to Atlassian's documentation and Atlassian Support for assistance setting up Jira correctly:

- [Adding a certificate to the trust store](https://confluence.atlassian.com/kb/how-to-import-a-public-ssl-certificate-into-a-jvm-867025849.html).
  - Simplest approach is to use [keytool](https://docs.oracle.com/javase/8/docs/technotes/tools/unix/keytool.html).
  - Add additional roots to Java's default truststore (`cacerts`) to allow Jira to
    also trust public certificate authorities.
  - If the integration stops working after upgrading Jira's Java runtime, this
    might be because the `cacerts` truststore got replaced.

- [Troubleshooting connectivity up to and including TLS handshaking](https://confluence.atlassian.com/kb/unable-to-connect-to-ssl-services-due-to-pkix-path-building-failed-error-779355358.html),
  using the a java class called `SSLPoke`.

- Download the class from Atlassian's knowledgebase to Jira's server, for example to `/tmp`.
- Use the same Java runtime as Jira.
- Pass all networking-related parameters that Jira is called with, such as proxy
  settings or an alternative root truststore (`-Djavax.net.ssl.trustStore`):

```shell
${JAVA_HOME}/bin/java -Djavax.net.ssl.trustStore=/var/atlassian/application-data/jira/cacerts -classpath /tmp SSLPoke gitlab.example.com 443
```

The message `Successfully connected` indicates a successful TLS handshake.

If there are problems, the Java TLS library generates errors that you can
look up for more detail.

##### Scope error when connecting Jira via DVCS

```plaintext
The requested scope is invalid, unknown, or malformed.
```

Potential resolutions:

- Verify the URL includes `scope=api` on the end of the URL.

##### Jira error adding account and no repositories listed

```plaintext
Error!
Failed adding the account: [Error retrieving list of repositories]
```

This error message is generated in Jira after completing the **Add New Account**
form in Jira and authorizing access. Attempting to click **Try Again** returns
`Account is already integrated with JIRA.` The account is set up in the DVCS
accounts view, but no repositories are listed.

Potential resolutions:

- If you're using GitLab versions 11.10-12.7, upgrade to GitLab 12.8.10 or later
  to resolve an identified [issue](https://gitlab.com/gitlab-org/gitlab/-/issues/37012).
- If you're using GitLab Core or GitLab Starter, be sure you're using
  GitLab 13.4 or later.

[Contact GitLab Support](https://about.gitlab.com/support) if none of these reasons apply.

#### Fixing synchronization issues

If Jira displays incorrect information (such as deleted branches), you may need to
resynchronize the information. To do so:

1. In Jira, go to **Jira Administration > Applications > DVCS accounts**.
1. At the account (group or subgroup) level, Jira displays an option to
   **Refresh repositories** in the `...` (ellipsis) menu.
1. For each project, there's a sync button displayed next to the **last activity** date.
   To perform a *soft resync*, click the button, or complete a *full sync* by shift clicking
   the button. For more information, see
   [Atlassian's documentation](https://confluence.atlassian.com/adminjiracloud/synchronize-an-account-972332890.html).

### GitLab for Jira app

You can integrate GitLab.com and Jira Cloud using the [GitLab for Jira](https://marketplace.atlassian.com/apps/1221011/gitlab-for-jira) app in the Atlassian Marketplace.

This method is recommended when using GitLab.com and Jira Cloud because data is synchronized in realtime, while the DVCS connector updates data only once per hour. If you are not using both of these environments, use the [Jira DVCS Connector](#jira-dvcs-configuration) method.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For a walkthrough of the integration with GitLab for Jira, watch [Configure GitLab Jira Integration using Marketplace App](https://youtu.be/SwR-g1s1zTo) on YouTube.

1. Go to **Jira Settings > Apps > Find new apps**, then search for GitLab.
1. Click **GitLab for Jira**, then click **Get it now**. Or go the [App in the marketplace directly](https://marketplace.atlassian.com/apps/1221011/gitlab-for-jira)

   ![Install GitLab App on Jira](img/jira_dev_panel_setup_com_1.png)
1. After installing, click **Get started** to go to the configurations page. This page is always available under **Jira Settings > Apps > Manage apps**.

   ![Start GitLab App configuration on Jira](img/jira_dev_panel_setup_com_2.png)
1. In **Namespace**, enter the group or personal namespace, and then click
   **Link namespace to Jira**. The user setting up *GitLab for Jira* must have
   *Maintainer* access to the GitLab namespace.

NOTE: **Note:**
The GitLab user only needs access when adding a new namespace. For syncing with Jira, we do not depend on the user's token.

   ![Configure namespace on GitLab Jira App](img/jira_dev_panel_setup_com_3.png)

After a namespace is added, all future commits, branches, and merge requests of all projects under that namespace are synced to Jira. Past data cannot be synced at the moment.

For more information, see [Usage](#usage).

#### Troubleshooting GitLab for Jira

The GitLab for Jira App uses an iframe to add namespaces on the settings page. Some browsers block cross-site cookies which can lead to a message saying that the user needs to log in on GitLab.com even though the user is already logged in.

> "You need to sign in or sign up before continuing."

In this case, use [Firefox](https://www.mozilla.org/en-US/firefox/), [Google Chrome](https://www.google.com/chrome/index.html) or enable cross-site cookies in your browser.

## Usage

After the integration is set up on GitLab and Jira, you can:

- Refer to any Jira issue by its ID in GitLab branch names, commit messages, and merge request
  titles.
- See the linked branches, commits, and merge requests in Jira issues (merge requests are
  called "pull requests" in Jira issues).

Jira issue IDs must be formatted in uppercase for the integration to work.

![Branch, Commit and Pull Requests links on Jira issue](img/jira_dev_panel_jira_setup_3.png)

Click the links to see your GitLab repository data.

![GitLab commits details on a Jira issue](img/jira_dev_panel_jira_setup_4.png)

![GitLab merge requests details on a Jira issue](img/jira_dev_panel_jira_setup_5.png)

For more information on using Jira Smart Commits to track time against an issue, specify an issue transition, or add a custom comment, see the Atlassian page [Using Smart Commits](https://confluence.atlassian.com/fisheye/using-smart-commits-960155400.html).

## Limitations

This integration is currently not supported on GitLab instances under a
[relative URL](https://docs.gitlab.com/omnibus/settings/configuration.html#configuring-a-relative-url-for-gitlab).
For example, `http://example.com/gitlab`.
