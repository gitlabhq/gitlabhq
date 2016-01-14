# GitLab Jira integration

GitLab can be configured to interact with Jira. Configuration happens via
username and password. Connecting to a Jira server via CAS is not possible.

Each project can be configured to connect to a different Jira instance, see the
[configuration](#configuration) section. If you have one Jira instance you can
pre-fill the settings page with a default template. To configure the template
see the [Services Templates][services-templates] document.

Once the project is connected to Jira, you can reference and close the issues
in Jira directly from GitLab.

## Table of Contents

* [Referencing Jira Issues from GitLab](#referencing-jira-issues)
* [Closing Jira Issues from GitLab](#closing-jira-issues)
* [Configuration](#configuration)

### Referencing Jira Issues

When GitLab project has Jira issue tracker configured and enabled, mentioning
Jira issue in GitLab will automatically add a comment in Jira issue with the
link back to GitLab. This means that in comments in merge requests and commits
referencing an issue, eg. `PROJECT-7`, will add a comment in Jira issue in the
format:

```
 USER mentioned this issue in LINK_TO_THE_MENTION
```

* `USER` A user that mentioned the issue. This is the link to the user profile in GitLab.
* `LINK_TO_THE_MENTION` Link to the origin of mention with a name of the entity where Jira issue was mentioned.
Can be commit or merge request.

![example of mentioning or closing the Jira issue](img/jira_issue_reference.png)

---

### Closing Jira Issues

Jira issues can be closed directly from GitLab by using trigger words, eg.
`Resolves PROJECT-1`, `Closes PROJECT-1` or `Fixes PROJECT-1`, in commits and
merge requests. When a commit which contains the trigger word in the commit
message is pushed, GitLab will add a comment in the mentioned Jira issue.

For example, for project named `PROJECT` in Jira, we implemented a new feature
and created a merge request in GitLab.

This feature was requested in Jira issue `PROJECT-7`. Merge request in GitLab
contains the improvement and in merge request description we say that this
merge request `Closes PROJECT-7` issue.

Once this merge request is merged, the Jira issue will be automatically closed
with a link to the commit that resolved the issue.

![A Git commit that causes the Jira issue to be closed](img/jira_merge_request_close.png)

---

![The GitLab integration user leaves a comment on Jira](img/jira_service_close_issue.png)

---

## Configuration

### Configuring JIRA

We need to create a user in JIRA which will have access to all projects that
need to integrate with GitLab. Login to your JIRA instance as admin and under
Administration go to User Management and create a new user.

As an example, we'll create a user named `gitlab` and add it to `jira-developers`
group.

**It is important that the user `gitlab` has write-access to projects in JIRA**

### Configuring GitLab

JIRA configuration in GitLab is done via a project's **Services**.

#### GitLab 7.8 and up with JIRA v6.x

See next section.

#### GitLab 7.8 and up

_The currently supported JIRA versions are v6.x and v7.x._

To enable JIRA integration in a project, navigate to the project's
**Settings > Services > JIRA**.

Fill in the required details on the page as described in the table below.

| Field | Description |
| ----- | ----------- |
| `URL` | The base URL to the JIRA project which is being linked to this GitLab project. Ex. https://jira.example.com |
| `Project key` | The short, all capital letter identifier for your JIRA project. |
| `Username` | The username of the user created in [configuring JIRA step](#configuring-jira). |
| `Password` |The password of the user created in [configuring JIRA step](#configuring-jira). |
| `Jira issue transition` | This is the ID of a transition that moves issues to a closed state. You can find this number under JIRA workflow administration ([see screenshot](img/jira_workflow_screenshot.png)).  By default, this ID is `2` (in the example image, this is `2` as well) |

After saving the configuration, your GitLab project will be able to interact
with the linked JIRA project.

![Jira service page](img/jira_service_page.png)

---

#### GitLab 6.x-7.7 with JIRA v6.x

_**Note:** GitLab versions 7.8 and up contain various integration improvements.
We strongly recommend upgrading._

In `gitlab.yml` enable the JIRA issue tracker section by
[uncommenting these lines][jira-gitlab-yml]. This will make sure that all
issues within GitLab are pointing to the JIRA issue tracker.

After you set this, you will be able to close issues in JIRA by a commit in
GitLab.

Go to your project's **Settings** page and fill in the project name for the
JIRA project:

![Set the JIRA project name in GitLab to 'NEW'](img/jira_project_name.png)

---

You can also enable the JIRA service that will allow you to interact with JIRA
issues. Go to the **Settings > Services > JIRA** and:

1. Tick the active check box to enable the service
1. Supply the URL to JIRA server, for example http://jira.example.com
1. Supply the username of a user we created under `Configuring JIRA` section,
   for example `gitlab`
1. Supply the password of the user
1. Optional: supply the JIRA API version, default is version `2`
1. Optional: supply the JIRA issue transition ID (issue transition to closed).
   This is dependent on JIRA settings, default is `2`
1. Hit save


![Jira services page](img/jira_service.png)

[services-templates]: ../project_services/services_templates.md
[jira-gitlab-yml]: https://gitlab.com/subscribers/gitlab-ee/blob/6-8-stable-ee/config/gitlab.yml.example#L111-115
