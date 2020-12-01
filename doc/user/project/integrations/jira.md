---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# GitLab Jira integration

If you need to use Jira to track work that's implemented in GitLab, GitLab's Jira integrations make the process of working across systems more efficient.

This page is about the GitLab Jira integration, which is available in every GitLab project by default, allowing you to connect it to any Jira instance, whether Cloud or self-managed. To compare features with the complementary Jira Development Panel integration, see [Jira integrations](jira_integrations.md).

After you set up this integration, you can cross-reference activity in the GitLab project with any of your projects in Jira. This includes the ability to close or transition Jira issues when work is completed in GitLab.

Features include:

- **Mention a Jira issue ID** in a commit message or MR (merge request) and
  - GitLab links to the Jira issue.
  - The Jira issue adds a comment with details and a link back to the activity in GitLab.
- **Mention that a commit or MR resolves or closes a specific Jira issue** and when it's merged to the default branch:
  - GitLab's MR displays a note that it closed the Jira issue. Prior to the merge, MRs indicate which issue they close.
  - The Jira issue shows the activity and is closed or otherwise transitioned as specified in your GitLab settings.
- **View a list of Jira issues directly in GitLab** **(PREMIUM)**

For additional features, you can install the
[Jira Development Panel integration](../../../integration/jira_development_panel.md).
This enables you to:

- In a Jira issue, display relevant GitLab information in the [development panel](https://support.atlassian.com/jira-software-cloud/docs/view-development-information-for-an-issue/), including related branches, commits, and merge requests.
- Use Jira [Smart Commits](https://confluence.atlassian.com/fisheye/using-smart-commits-960155400.html) in GitLab to add Jira comments, log time spent on the issue, or apply any issue transition.

See the [feature comparison](jira_integrations.md#feature-comparison) for more details.

## Configuration

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [Agile Management - GitLab-Jira Basic Integration](https://www.youtube.com/watch?v=fWvwkx5_00E&feature=youtu.be).

Each GitLab project can be configured to connect to an entire Jira instance. That
means one GitLab project can interact with _all_ Jira projects in that instance, once
configured. Therefore, you do not have to explicitly associate
a GitLab project with any single Jira project.

If you have one Jira instance, you can pre-fill the settings page with a default
template. See the [Services Templates](services_templates.md) docs.

In order to enable the Jira service in GitLab, you need to first configure the project in Jira and then enter the correct values in GitLab.

### Configuring Jira

#### Jira Server

**Jira Server** supports basic authentication. When connecting, a **username and password** are required. Note that connecting to Jira Server via CAS is not possible. [Set up a user in Jira Server](jira_server_configuration.md) first and then proceed to [Configuring GitLab](#configuring-gitlab).

#### Jira Cloud

**Jira Cloud** supports authentication through an API token. When connecting to **Jira Cloud**, an **email and API token** are required. [Set up a user in Jira Cloud](jira_cloud_configuration.md) first and then proceed to [Configuring GitLab](#configuring-gitlab).

### Configuring GitLab

> **Notes:**
>
> - The supported Jira versions are `v6.x`, `v7.x`, and `v8.x`.
> - In order to support Oracle's Access Manager, GitLab sends additional cookies
>   to enable Basic Auth. The cookie being added to each request is `OBBasicAuth` with
>   a value of `fromDialog`.

To enable the Jira integration in a project, navigate to the
[Integrations page](overview.md#accessing-integrations) and click
the **Jira** service.

Select **Enable integration**.

Select a **Trigger** action. This determines whether a mention of a Jira issue in GitLab commits, merge requests, or both, should link the Jira issue back to that source commit/MR and transition the Jira issue, if indicated.

To include a comment on the Jira issue when the above reference is made in GitLab, check **Enable comments**.

Enter the further details on the page as described in the following table.

| Field | Description |
| ----- | ----------- |
| `Web URL` | The base URL to the Jira instance web interface which is being linked to this GitLab project. E.g., `https://jira.example.com`. |
| `Jira API URL` | The base URL to the Jira instance API. Web URL value is used if not set. For example, `https://jira-api.example.com`. Leave this field blank (or use the same value of `Web URL`) if using **Jira Cloud**. |
| `Username or Email` | Created in [configuring Jira](#configuring-jira) step. Use `username` for **Jira Server** or `email` for **Jira Cloud**. |
| `Password/API token` |Created in [configuring Jira](#configuring-jira) step. Use `password` for **Jira Server** or `API token` for **Jira Cloud**. |
| `Transition ID` | Required for closing Jira issues via commits or merge requests. This is the ID of a transition in Jira that moves issues to a desired state. (See [Obtaining a transition ID](#obtaining-a-transition-id).) If you insert multiple transition IDs separated by `,` or `;`, the issue is moved to each state, one after another, using the given order. |

To enable users to view Jira issues inside the GitLab project, select **Enable Jira issues** and enter a Jira project key. **(PREMIUM)**

You can only display issues from a single Jira project within a given GitLab project.

CAUTION: **Caution:**
If you enable Jira issues with the setting above, all users that have access to this GitLab project
are able to view all issues from the specified Jira project.

When you have configured all settings, click **Test settings and save changes**.

Your GitLab project can now interact with all Jira projects in your instance and the project now displays a Jira link that opens the Jira project.

#### Obtaining a transition ID

In the most recent Jira user interface, you can no longer see transition IDs in the workflow
administration UI. You can get the ID you need in either of the following ways:

1. By using the API, with a request like `https://yourcompany.atlassian.net/rest/api/2/issue/ISSUE-123/transitions`
   using an issue that is in the appropriate "open" state
1. By mousing over the link for the transition you want and looking for the
   "action" parameter in the URL

Note that the transition ID may vary between workflows (e.g., bug vs. story),
even if the status you are changing to is the same.

#### Disabling comments on Jira issues

You can continue to have GitLab cross-link a source commit/MR with a Jira issue while disabling the comment added to the issue.

See the [Configuring GitLab](#configuring-gitlab) section and uncheck the **Enable comments** setting.

## Jira issues

By now you should have [configured Jira](#configuring-jira) and enabled the
[Jira service in GitLab](#configuring-gitlab). If everything is set up correctly
you should be able to reference and close Jira issues by just mentioning their
ID in GitLab commits and merge requests.

Jira issue IDs must be formatted in uppercase for the integration to work.

### Reference Jira issues

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

### Close Jira issues

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

### View Jira issues **(PREMIUM)**

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/3622) in [GitLab Premium](https://about.gitlab.com/pricing/) 13.2.

You can browse and search issues from a selected Jira project directly in GitLab. This requires [configuration](#configuring-gitlab) in GitLab by an administrator.

![Jira issues integration enabled](img/jira/open_jira_issues_list_v13.2.png)

From the **Jira Issues** menu, click **Issues List**. The issue list defaults to sort by **Created date**, with the newest issues listed at the top. You can change this to **Last updated**.

Issues are grouped into tabs based on their [Jira status](https://confluence.atlassian.com/adminjiraserver070/defining-status-field-values-749382903.html).

- The **Open** tab displays all issues with a Jira status in any category other than Done.
- The **Closed** tab displays all issues with a Jira status categorized as Done.
- The **All** tab displays all issues of any status.

Click an issue title to open its original Jira issue page for full details.

#### Search and filter the issues list

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
