# GitLab JIRA Development Panel integration **[PREMIUM]**

> [Introduced][ee-2381] in [GitLab Premium][eep] 10.0.

As an extension to our [existing JIRA][existing-jira] project integration, you're now able to integrate
GitLab projects with [JIRA Development Panel][jira-development-panel]. Both can be used
simultaneously. This works with self-hosted GitLab or GitLab.com integrated with self-hosted JIRA
or cloud JIRA.

By doing this you can easily access related GitLab merge requests, branches, and commits directly from a JIRA issue.

This integration connects all GitLab projects within a top-level group or a personal namespace to projects in the JIRA instance.
A top-level GitLab group is one that does not have any parent group itself. All the projects of that top-level group,
as well as projects of the top-level group's subgroups nesting down, are connected. Alternatively, you can specify
a GitLab personal namespace in the JIRA configuration, which will then connect the projects in that personal namespace to JIRA.

(Note this is different from the [existing JIRA][existing-jira] project integration, where the mapping
is one GitLab project to the entire JIRA instance.) 

We recommend that a GitLab group admin
or instance admin (in the case of self-hosted GitLab) set up the integration with respect to their
account, in order to maximize the integrated GitLab projects used by your team.

## GitLab Configuration

1. In GitLab, create a new application in order to allow JIRA to connect with your GitLab account

    While logged-in, go to `Settings -> Applications`. (Click your profile avatar at
    the top right, choose `Settings`, and then navigate to `Applications` from the left
    navigation menu.) Use the form to create a new application.

    Enter a useful name for the `Name` field.

    For the `Redirect URI` field, enter `https://<your-gitlab-instance-domain>/-/jira/login/oauth/callback`,
    replacing `<your-gitlab-instance-domain>` appropriately. So for example, if you are using GitLab.com,
    this would be `https://gitlab.com/-/jira/login/oauth/callback`.

    ![GitLab Application setup](img/jira_dev_panel_gl_setup_1.png)
    - Check `api` in the Scopes section.

2. Click `Save application`. You will see the generated 'Application Id' and 'Secret' values.
Copy these values that you will use on the JIRA configuration side.

## JIRA Configuration

1. In JIRA, from the gear menu at the top right, go to `Applications`. Navigate to `DVCS accounts`
from the left navigation menu. Click `Link GitHub account` to start creating a new integration.
(We are pretending to be GitHub in this integration until there is further platform support from JIRA.)

    ![JIRA DVCS from Dashboard](img/jira_dev_panel_jira_setup_1.png)

2. Complete the form

    Select GitHub Enterprise for the `Host` field.

    For the `Team or User Account` field, enter the relative path of a top-level GitLab group that you have access to,
    or the relative path of your personal namespace.

    ![Creation of Jira DVCS integration](img/jira_dev_panel_jira_setup_2.png)

    For the `Host URL` field, enter `https://<your-gitlab-instance-domain>/-/jira`,
    replacing `<your-gitlab-instance-domain>` appropriately. So for example, if you are using GitLab.com,
    this would be `https://gitlab.com/-/jira`.

    For the `Client ID` field, use the `Application ID` value from the previous section.

    For the `Client Secret` field, use the `Secret` value from the previous section.

    Ensure that the rest of the checkboxes are checked.

3. Click `Add` to complete and create the integration.

    JIRA takes up to a few minutes to know about (import behind the scenes) all the commits and branches
    for all the projects in the GitLab group you specified in the previous step. These are refreshed
    every 60 minutes.

    >**Note:**
    In the future, we plan on implementating real-time integration. If you need
    to refresh the data manually, you can do this from the `Applications -> DVCS
    accounts` screen where you initially set up the integration:

    > ![Refresh GitLab information in JIRA](img/jira_dev_panel_manual_refresh.png)

To connect additional GitLab projects from other GitLab top-level groups (or personal namespaces), repeat the above
steps with additional JIRA DVCS accounts.

You may now refer any Jira issue by its ID in branch names, commit messages and  merge request names on GitLab's side,
and you will be able to see the linked `branches`, `commits`, and `merge requests` when entering a JIRA issue
(inside the Jira issue, merge requests will be called "pull requests").


![Branch, Commit and Pull Requests links on JIRA issue](img/jira_dev_panel_jira_setup_3.png)

Click the links to see your GitLab repository data.

![GitLab commits details on a JIRA issue](img/jira_dev_panel_jira_setup_4.png)

![GitLab merge requests details on a JIRA issue](img/jira_dev_panel_jira_setup_5.png)


## Limitations

- This integration is currently not supported on GitLab instances under a [relative url][relative-url] (e.g. `http://example.com/gitlab`).

[existing-jira]: ../user/project/integrations/jira.md
[jira-development-panel]: https://confluence.atlassian.com/adminjiraserver070/integrating-with-development-tools-776637096.html#Integratingwithdevelopmenttools-Developmentpanelonissues
[eep]: https://about.gitlab.com/pricing/
[ee-2381]: https://gitlab.com/gitlab-org/gitlab-ee/issues/2381
[relative-url]: https://docs.gitlab.com/omnibus/settings/configuration.html#configuring-a-relative-url-for-gitlab
