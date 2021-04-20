---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Jira integration issue management **(FREE)**

By now you should have [configured Jira](development_panel.md#configuration) and enabled the
[Jira service in GitLab](development_panel.md#configure-gitlab). If everything is set up correctly
you should be able to reference and close Jira issues by just mentioning their
ID in GitLab commits and merge requests.

Jira issue IDs must be formatted in uppercase for the integration to work.

## Reference Jira issues

When GitLab project has Jira issue tracker configured and enabled, mentioning
Jira issues in GitLab automatically adds a comment in Jira issue with the
link back to GitLab. This means that in comments in merge requests and commits
referencing an issue, `PROJECT-7` for example, adds a comment in Jira issue in the
format:

```plaintext
USER mentioned this issue in RESOURCE_NAME of [PROJECT_NAME|LINK_TO_COMMENT]:
ENTITY_TITLE
```

- `USER` A user that mentioned the issue. This is the link to the user profile in GitLab.
- `LINK_TO_THE_COMMENT` Link to the origin of mention with a name of the entity where Jira issue was mentioned.
- `RESOURCE_NAME` Kind of resource which referenced the issue. Can be a commit or merge request.
- `PROJECT_NAME` GitLab project name.
- `ENTITY_TITLE` Merge request title or commit message first line.

![example of mentioning or closing the Jira issue](img/jira_issue_reference.png)

For example, the following commit references the Jira issue with `PROJECT-1` as its ID:

```shell
git commit -m "PROJECT-1 Fix spelling and grammar"
```

## Close Jira issues

Jira issues can be closed directly from GitLab by using trigger words in
commits and merge requests. When a commit which contains the trigger word
followed by the Jira issue ID in the commit message is pushed, GitLab
adds a comment in the mentioned Jira issue and immediately closes it (provided
the transition ID was set up correctly).

There are currently three trigger words, and you can use either one to achieve
the same goal:

- `Resolves PROJECT-1`
- `Closes PROJECT-1`
- `Fixes PROJECT-1`

where `PROJECT-1` is the ID of the Jira issue.

Note the following:

- Only commits and merges into the project's default branch (usually `master`)
  close an issue in Jira. You can change your project's default branch under
  [project settings](img/jira_project_settings.png).
- The Jira issue is not transitioned if it has a resolution.

Let's consider the following example:

1. For the project named `PROJECT` in Jira, we implemented a new feature
   and created a merge request in GitLab.
1. This feature was requested in Jira issue `PROJECT-7` and the merge request
   in GitLab contains the improvement
1. In the merge request description we use the issue closing trigger
   `Closes PROJECT-7`.
1. Once the merge request is merged, the Jira issue is automatically closed
   with a comment and an associated link to the commit that resolved the issue.

In the following screenshot you can see what the link references to the Jira
issue look like.

![A Git commit that causes the Jira issue to be closed](img/jira_merge_request_close.png)

Once this merge request is merged, the Jira issue is automatically closed
with a link to the commit that resolved the issue.

![The GitLab integration closes Jira issue](img/jira_service_close_issue.png)

## View Jira issues **(PREMIUM)**

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/3622) in [GitLab Premium](https://about.gitlab.com/pricing/) 13.2.

You can browse, search, and view issues from a selected Jira project directly in GitLab,
if your GitLab administrator [has configured it](development_panel.md#configure-gitlab):

1. In the left navigation bar, go to **Jira > Issues list**.
1. The issue list sorts by **Created date** by default, with the newest issues listed at the top:

   ![Jira issues integration enabled](img/open_jira_issues_list_v13.2.png)

1. To display the most recently updated issues first, click **Last updated**.
1. In GitLab versions 13.10 and later, you can view [individual Jira issues](#view-a-jira-issue).

Issues are grouped into tabs based on their [Jira status](https://confluence.atlassian.com/adminjiraserver070/defining-status-field-values-749382903.html):

- The **Open** tab displays all issues with a Jira status in any category other than Done.
- The **Closed** tab displays all issues with a Jira status categorized as Done.
- The **All** tab displays all issues of any status.

## View a Jira issue

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/299832) in [GitLab Premium](https://about.gitlab.com/pricing/) 13.10 behind a feature flag, disabled by default.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/299832) in [GitLab Premium](https://about.gitlab.com/pricing/) 13.11.

When viewing the [Jira issues list](#view-jira-issues), select an issue from the
list to open it in GitLab:

![Jira issue detail view](img/jira_issue_detail_view_v13.10.png)

## Search and filter the issues list

To refine the list of issues, use the search bar to search for any text
contained in an issue summary (title) or description.

You can also filter by labels, status, reporter, and assignee using URL parameters.
Enhancements to be able to use these through the user interface are [planned](https://gitlab.com/groups/gitlab-org/-/epics/3622).

- To filter issues by `labels`, specify one or more labels as part of the `labels[]`
parameter in the URL. When using multiple labels, only issues that contain all specified
labels are listed. `/-/integrations/jira/issues?labels[]=backend&labels[]=feature&labels[]=QA`

- To filter issues by `status`, specify the `status` parameter in the URL.
`/-/integrations/jira/issues?status=In Progress`

- To filter issues by `reporter`, specify a reporter's Jira display name for the
`author_username` parameter in the URL. `/-/integrations/jira/issues?author_username=John Smith`

- To filter issues by `assignee`, specify their Jira display name for the
`assignee_username` parameter in the URL. `/-/integrations/jira/issues?assignee_username=John Smith`

## Automatic issue transitions

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/...) in GitLab 13.10.

In this mode the referenced Jira issue is transitioned to the next available status with a category of "Done".

See the [Configure GitLab](development_panel.md#configure-gitlab) section, check the **Enable Jira transitions** setting and select the **Move to Done** option.

## Custom issue transitions

For advanced workflows you can specify custom Jira transition IDs.

See the [Configure GitLab](development_panel.md#configure-gitlab) section, check the **Enable Jira transitions** setting, select the **Custom transitions** option, and enter your transition IDs in the text field.

If you insert multiple transition IDs separated by `,` or `;`, the issue is moved to each state, one after another, using the given order. If a transition fails the sequence is aborted.

To see the transition IDs on Jira Cloud, edit a workflow in the **Text** view.
The transition IDs display in the **Transitions** column.

On Jira Server you can get the transition IDs in either of the following ways:

1. By using the API, with a request like `https://yourcompany.atlassian.net/rest/api/2/issue/ISSUE-123/transitions`
   using an issue that is in the appropriate "open" state
1. By mousing over the link for the transition you want and looking for the
   "action" parameter in the URL

Note that the transition ID may vary between workflows (for example, bug vs. story),
even if the status you are changing to is the same.

## Disabling comments on Jira issues

You can continue to have GitLab cross-link a source commit/MR with a Jira issue while disabling the comment added to the issue.

See the [Configure GitLab](development_panel.md#configure-gitlab) section and uncheck the **Enable comments** setting.
