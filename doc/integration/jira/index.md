---
stage: Manage
group: Integrations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Jira **(FREE)**

If your organization uses [Jira](https://www.atlassian.com/software/jira),
you can [migrate your issues from Jira to GitLab](../../user/project/import/jira.md).
If you want to continue to use Jira, you can integrate Jira with GitLab instead.

## Jira integrations

GitLab offers two types of Jira integrations. You can
use one or both depending on the capabilities you need.

### Jira issue integration

You can use the [Jira issue integration](configure.md) developed by GitLab with Jira Cloud, Jira Data Center, or Jira Server. With this integration, you can:

- View and search Jira issues directly in GitLab.
- Refer to Jira issues by ID in GitLab commits and merge requests.
- Create Jira issues for vulnerabilities.

### Jira development panel

You can use the [Jira development panel](development_panel.md) to [view GitLab activity for an issue](https://support.atlassian.com/jira-software-cloud/docs/view-development-information-for-an-issue/)
including related branches, commits, and merge requests. To configure the Jira development panel:

- **For Jira Cloud**, use the [GitLab for Jira Cloud app](connect-app.md) developed by GitLab.
- **For Jira Data Center or Jira Server**, use the [Jira DVCS connector](dvcs/index.md) developed by Atlassian.

## Jira integration capabilities

| Capability | Jira issue integration | Jira development panel |
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

## Privacy considerations

All Jira integrations share data with Jira to make it visible outside of GitLab.
If you integrate a private GitLab project with Jira, the private data is
shared with users who have access to your Jira project.

The [Jira issue integration](configure.md) posts GitLab data in the form of comments in Jira issues.
The GitLab for Jira Cloud app and Jira DVCS connector share this data through the [Jira development panel](development_panel.md).
This method provides more fine-grained access control because access can be restricted to certain user groups or roles.

## Third-party Jira integrations

Developers have built several third-party Jira integrations for GitLab that are
listed on the [Atlassian Marketplace](https://marketplace.atlassian.com/search?product=jira&query=gitlab).
