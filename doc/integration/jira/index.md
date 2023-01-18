---
stage: Manage
group: Integrations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Jira integrations **(FREE)**

If your organization uses [Jira](https://www.atlassian.com/software/jira) issues,
you can [migrate your issues from Jira](../../user/project/import/jira.md) and work
exclusively in GitLab. However, if you'd like to continue to use Jira, you can
integrate it with GitLab. GitLab offers two types of Jira integrations, and you
can use one or both depending on the capabilities you need. We recommend you enable both.

## Compare integrations

After you set up one or both of these integrations, you can cross-reference activity
in your GitLab project with any of your projects in Jira.

### Jira integration

This integration connects one or more GitLab projects to a Jira instance. The Jira instance
can be hosted by you or in [Atlassian cloud](https://www.atlassian.com/migration/assess/why-cloud).
The supported Jira versions are `v6.x`, `v7.x`, and `v8.x`.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [Agile Management - GitLab-Jira Basic Integration](https://www.youtube.com/watch?v=fWvwkx5_00E&feature=youtu.be).

To set up the integration, [configure the settings](configure.md) in GitLab.

### Jira development panel integration

The [Jira development panel integration](development_panel.md)
connects all GitLab projects under a group or personal namespace. When configured,
relevant GitLab information, including related branches, commits, and merge requests,
displays in the [development panel](https://support.atlassian.com/jira-software-cloud/docs/view-development-information-for-an-issue/).

To set up the Jira development panel integration, use the GitLab.com for Jira Cloud app
or the Jira DVCS (distributed version control system) connector,
[depending on your installation](development_panel.md#configure-the-integration).

### Direct feature comparison

| Capability | Jira integration | Jira development panel integration |
|-|-|-|
| Mention a Jira issue ID in a GitLab commit or merge request, and a link to the Jira issue is created. | Yes. | No. |
| Mention a Jira issue ID in GitLab and the Jira issue shows the GitLab issue or merge request. | Yes. A Jira comment with the GitLab issue or MR title links to GitLab. The first mention is also added to the Jira issue under **Web links**. | Yes, in the issue's [development panel](https://support.atlassian.com/jira-software-cloud/docs/view-development-information-for-an-issue/). |
| Mention a Jira issue ID in a GitLab commit message and the Jira issue shows the commit message. | Yes. The entire commit message is displayed in the Jira issue as a comment and under **Web links**. Each message links back to the commit in GitLab. | Yes, in the issue's [development panel](https://support.atlassian.com/jira-software-cloud/docs/view-development-information-for-an-issue/) and optionally with a custom comment on the Jira issue using Jira [Smart Commits](https://confluence.atlassian.com/fisheye/using-smart-commits-960155400.html). |
| Mention a Jira issue ID in a GitLab branch name and the Jira issue shows the branch name. | No. | Yes, in the issue's [development panel](https://support.atlassian.com/jira-software-cloud/docs/view-development-information-for-an-issue/). |
| Add Jira time tracking to an issue. | No. | Yes. Time can be specified using Jira Smart Commits. |
| Use a Git commit or merge request to transition or close a Jira issue. | Yes. Only a single transition type, typically configured to close the issue by setting it to Done. | Yes. Transition to any state using Jira Smart Commits. |
| Display a list of [Jira issues](issues.md#view-jira-issues). | Yes. | No. |
| Create a Jira issue from a [vulnerability or finding](../../user/application_security/vulnerabilities/index.md#create-a-jira-issue-for-a-vulnerability). | Yes. | No. |
| Create a GitLab branch from a Jira issue. | No. | Yes, in the issue's [development panel](https://support.atlassian.com/jira-software-cloud/docs/view-development-information-for-an-issue/). |
| Mention a Jira issue ID in a GitLab merge request, and deployments are synced. | No. | Yes, in the issue's [development panel](https://support.atlassian.com/jira-software-cloud/docs/view-development-information-for-an-issue/). |

## Authentication in Jira

The authentication method in Jira depends on whether you host Jira on your own server or on
[Atlassian cloud](https://www.atlassian.com/migration/assess/why-cloud):

- **Jira Server** supports basic authentication. When connecting, a **username and password** are
  required. Connecting to Jira Server using the Central Authentication Service (CAS) is not possible. For more information, read
  how to [set up a user in Jira Server](jira_server_configuration.md).
- **Jira on Atlassian cloud** supports authentication through an API token. When connecting to Jira on
  Atlassian cloud, an email and API token are required. For more information, read
  [create an API token for Jira in Atlassian cloud](jira_cloud_configuration.md).

## Privacy considerations

All Jira integrations share data with Jira to make it visible outside of GitLab.
If you integrate a private GitLab project with Jira, the private data is
shared with users who have access to your Jira project.

The [**Jira project integration**](#jira-integration) posts GitLab data in the form of comments in Jira issues.
The GitLab.com for Jira Cloud app and Jira DVCS connector share this data through the [**Jira Development Panel**](development_panel.md).
This method provides more fine-grained access control because access can be restricted to certain user groups or roles.

## Third-party Jira integrations

Developers have built several third-party Jira integrations for GitLab that are
listed on the [Atlassian Marketplace](https://marketplace.atlassian.com/search?product=jira&query=gitlab).
