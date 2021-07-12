---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Jira integrations **(FREE)**

If your organization uses [Jira](https://www.atlassian.com/software/jira) issues,
you can [migrate your issues from Jira](../../user/project/import/jira.md) **(PREMIUM)** and work
exclusively in GitLab. However, if you'd like to continue to use Jira, you can
integrate it with GitLab. GitLab offers two types of Jira integrations, and you
can use one or both depending on the capabilities you need. It is recommended that you enable both.

## Compare integrations

After you set up one or both of these integrations, you can cross-reference activity
in your GitLab project with any of your projects in Jira.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [Agile Management - GitLab-Jira Basic Integration](https://www.youtube.com/watch?v=fWvwkx5_00E&feature=youtu.be).

### Jira integration

This integration connects one or more GitLab project to a Jira instance. The Jira instance
can be hosted by you or in [Atlassian cloud](https://www.atlassian.com/cloud).
The supported Jira versions are `v6.x`, `v7.x`, and `v8.x`.
To simplify administration, we recommend that a GitLab group maintainer or group owner
(or instance administrator in the case of self-managed GitLab) set up the integration.

- *If your installation uses Jira Cloud,* use the
  [GitLab for Jira app](connect-app.md).
- *If either your Jira or GitLab installation is self-managed,* use the
  [Jira DVCS Connector](dvcs.md).

### Jira development panel integration

The [Jira development panel integration](development_panel.md)
connects all GitLab projects under a group or personal namespace. When configured,
relevant GitLab information, including related branches, commits, and merge requests,
displays in the [development panel](https://support.atlassian.com/jira-software-cloud/docs/view-development-information-for-an-issue/).

### Direct feature comparison

| Capability | Jira integration | Jira Development panel integration |
|-|-|-|
| Mention a Jira issue ID in a GitLab commit or merge request, and a link to the Jira issue is created. | Yes. | No. |
| Mention a Jira issue ID in GitLab and the Jira issue shows the GitLab issue or merge request. | Yes. A Jira comment with the GitLab issue or MR title links to GitLab. The first mention is also added to the Jira issue under **Web links**. | Yes, in the issue's Development panel. |
| Mention a Jira issue ID in a GitLab commit message and the Jira issue shows the commit message. | Yes. The entire commit message is displayed in the Jira issue as a comment and under **Web links**. Each message links back to the commit in GitLab. | Yes, in the issue's Development panel and optionally with a custom comment on the Jira issue using Jira [Smart Commits](https://confluence.atlassian.com/fisheye/using-smart-commits-960155400.html). |
| Mention a Jira issue ID in a GitLab branch name and the Jira issue shows the branch name. | No. | Yes, in the issue's [development panel](https://support.atlassian.com/jira-software-cloud/docs/view-development-information-for-an-issue/). |
| Add Jira time tracking to an issue. | No. | Yes. Time can be specified using Jira Smart Commits. |
| Use a Git commit or merge request to transition or close a Jira issue. | Yes. Only a single transition type, typically configured to close the issue by setting it to Done. | Yes. Transition to any state using Jira Smart Commits. |
| Display a list of Jira issues. | Yes. **(PREMIUM)** | No. |
| Create a Jira issue from a vulnerability or finding. | Yes. **(ULTIMATE)** | No. |

## Authentication in Jira

The process for configuring Jira depends on whether you host Jira on your own server or on
[Atlassian cloud](https://www.atlassian.com/cloud):

- **Jira Server** supports basic authentication. When connecting, a **username and password** are
  required. Connecting to Jira Server via CAS is not possible. For more information, read
  how to [set up a user in Jira Server](jira_server_configuration.md).
- **Jira on Atlassian cloud** supports authentication through an API token. When connecting to Jira on
  Atlassian cloud, an email and API token are required. For more information, read
  [set up a user in Jira on Atlassian cloud](jira_cloud_configuration.md).

## Privacy considerations

If you integrate a private GitLab project with Jira using the [**Jira integration**](#jira-integration),
actions in GitLab issues and merge requests linked to a Jira issue leak information
about the private project to non-administrator Jira users. If your installation uses Jira Cloud,
you can use the [GitLab.com for Jira Cloud app](connect-app.md) to avoid this risk.

## Troubleshooting

If these features do not work as expected, it is likely due to a problem with the way the integration settings were configured.

### GitLab is unable to comment on a Jira issue

Make sure that the Jira user you set up for the integration has the
correct access permission to post comments on a Jira issue and also to transition
the issue, if you'd like GitLab to also be able to do so.
Jira issue references and update comments do not work if the GitLab issue tracker is disabled.

### GitLab is unable to close a Jira issue

Make sure the `Transition ID` you set within the Jira settings matches the one
your project needs to close an issue.

Make sure that the Jira issue is not already marked as resolved; that is,
the Jira issue resolution field is not set. (It should not be struck through in
Jira lists.)

### CAPTCHA

CAPTCHA may be triggered after several consecutive failed login attempts
which may lead to a `401 unauthorized` error when testing your Jira integration.
If CAPTCHA has been triggered, you can't use Jira's REST API to
authenticate with the Jira site. You need to log in to your Jira instance
and complete the CAPTCHA.
