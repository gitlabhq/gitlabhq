# External issue tracker

GitLab has a great issue tracker but you can also use an external issue tracker such as Jira, Bugzilla or Redmine. You can configure issue trackers per GitLab project. For instance, if you configure Jira it allows you to do the following:

- the 'Issues' link on the GitLab project pages takes you to the appropriate Jira issue index;
- clicking 'New issue' on the project dashboard creates a new Jira issue;
- To reference Jira issue PROJECT-1234 in comments, use syntax PROJECT-1234. Commit messages get turned into HTML links to the corresponding Jira issue.

![Jira screenshot](jira-integration-points.png)

GitLab Enterprise Edition contains [advanced JIRA support](http://doc.gitlab.com/ee/integration/jira.html).

## Configuration

### Project Service

You can enable an external issue tracker per project. As an example, we will configure `Redmine` for project named gitlab-ci.

Fill in the required details on the page:

![redmine configuration](redmine_configuration.png)

* `description` A name for the issue tracker (to differentiate between instances, for example).
* `project_url` The URL to the project in Redmine which is being linked to this GitLab project.
* `issues_url` The URL to the issue in Redmine project that is linked to this GitLab project. Note that the `issues_url` requires `:id` in the url. This id is used by GitLab as a placeholder to replace the issue number.
* `new_issue_url` This is the URL to create a new issue in Redmine for the project linked to this GitLab project.

### Service Template

It is necessary to configure the external issue tracker per project, because project specific details are needed for the integration with GitLab.
The admin can add a service template that sets a default for each project. This makes it much easier to configure individual projects.

In GitLab Admin section, navigate to `Service Templates` and choose the service template you want to create:

![redmine service template](redmine_service_template.png)

After the template is created, the template details will be pre-filled on the project service page.

NOTE: For each project, you will still need to configure the issue tracking URLs by replacing `:issues_tracker_id` in the above screenshot
with the ID used by your external issue tracker. Prior to GitLab v7.8, this ID was configured in the project settings, and GitLab would automatically
update the URL configured in `gitlab.yml`. This behavior is now depecated, and all issue tracker URLs must be configured directly
within the project's Services settings.

Support to add your commits to the Jira ticket automatically is [available in GitLab EE](http://doc.gitlab.com/ee/integration/jira.html).
