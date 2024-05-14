---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Jira

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

You can [import your Jira issues to GitLab](../../user/project/import/jira.md).
If you want to continue to use Jira, you can integrate Jira with GitLab instead.

## Jira integrations

GitLab offers two Jira integrations. You can use one or both integrations
[depending on the features you need](#feature-availability).

### Jira issue integration

You can use the [Jira issue integration](configure.md) developed by GitLab with
Jira Cloud, Jira Data Center, or Jira Server. With this integration, you can:

- View and search Jira issues directly in GitLab.
- Refer to Jira issues by ID in GitLab commits and merge requests.
- Create Jira issues for vulnerabilities.

### Jira development panel

You can use the [Jira development panel](development_panel.md) to
[view GitLab activity for an issue](https://support.atlassian.com/jira-software-cloud/docs/view-development-information-for-an-issue/)
including related branches, commits, and merge requests. To configure the Jira development panel:

- **For Jira Cloud**, use the [GitLab for Jira Cloud app](connect-app.md) developed and maintained by GitLab.
- **For Jira Data Center or Jira Server**, use the [Jira DVCS connector](dvcs/index.md) developed and maintained by Atlassian.

## Feature availability

This table shows the features available with the Jira issue integration and the Jira development panel:

| Feature | Jira issue integration | Jira development panel |
|-|-|-|
| Mention a Jira issue ID in a GitLab commit or merge request, and a link to the Jira issue is created. | **{check-circle}** Yes | **{dotted-circle}** No |
| Mention a Jira issue ID in GitLab, and the Jira issue shows the GitLab issue or merge request. | **{check-circle}** Yes, a Jira comment with the GitLab issue or merge request title links to GitLab. The first mention is also added to **Web links** in the Jira issue. | **{check-circle}** Yes, in the Jira issue's [development panel](https://support.atlassian.com/jira-software-cloud/docs/view-development-information-for-an-issue/). |
| Mention a Jira issue ID in a GitLab commit, and the Jira issue shows the commit message. | **{check-circle}** Yes, the entire commit message is displayed in the Jira issue as a comment and in **Web links**. Each message links back to the commit in GitLab. | **{check-circle}** Yes, in the Jira issue's development panel. A custom comment is possible with [Jira Smart Commits](https://confluence.atlassian.com/fisheye/using-smart-commits-960155400.html). |
| Mention a Jira issue ID in a GitLab branch name, and the Jira issue shows the branch name. | **{dotted-circle}** No | **{check-circle}** Yes, in the Jira issue's development panel. |
| Add time tracking to a Jira issue. | **{dotted-circle}** No | **{check-circle}** Yes, with Jira Smart Commits. |
| Use a GitLab commit or merge request to transition a Jira issue. |**{check-circle}** Yes, only a single transition. Typically used to close the Jira issue. | **{check-circle}** Yes, transition the Jira issue to any state with Jira Smart Commits. |
| [View a list of Jira issues](configure.md#view-jira-issues). | **{check-circle}** Yes | **{dotted-circle}** No |
| [Create a Jira issue for a vulnerability](configure.md#create-a-jira-issue-for-a-vulnerability). | **{check-circle}** Yes | **{dotted-circle}** No |
| Create a GitLab branch from a Jira issue. | **{dotted-circle}** No | **{check-circle}** Yes, in the Jira issue's development panel. |
| Mention a Jira issue ID in a GitLab merge request, branch name, or any of the last 5,000 commits to the branch after the last successful deployment to the environment to sync a GitLab deployment to a Jira issue. | **{dotted-circle}** No | **{check-circle}** Yes, in the Jira issue's development panel. |

## Privacy considerations

All Jira integrations share data outside of GitLab.
If you integrate a private GitLab project with Jira, the private
data is shared with users who have access to your Jira project.

The [Jira issue integration](configure.md) posts GitLab data as comments on Jira issues.
The [GitLab for Jira Cloud app](connect-app.md) and the [Jira DVCS connector](dvcs/index.md)
share GitLab data through the [Jira development panel](development_panel.md).
With the Jira development panel, you can restrict access to certain user groups or roles.

## Related topics

- [Third-party Jira integrations](https://marketplace.atlassian.com/search?product=jira&query=gitlab)
