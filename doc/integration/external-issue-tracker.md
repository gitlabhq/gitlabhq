# External issue tracker

GitLab has a great issue tracker but you can also use an external issue tracker such as Jira, Bugzilla or Redmine. This is something that you can turn on per GitLab project. If for example you configure Jira it provides the following functionality:

- the 'Issues' link on the GitLab project pages takes you to the appropriate Jira issue index;
- clicking 'New issue' on the project dashboard creates a new Jira issue;
- To reference Jira issue PROJECT-1234 in comments, use syntax PROJECT-1234. Commit messages get turned into HTML links to the corresponding Jira issue.

![Jira screenshot](jira-integration-points.png)

## Configuration

### Project Service

External issue tracker can be enabled per project basis. As an example, we will configure `Redmine` for project named gitlab-ci.

Fill in the required details on the page:

![redmine configuration](redmine_configuration.png)

* `description` A name for the issue tracker (to differentiate between instances, for example).
* `project_url` The URL to the project in Redmine which is being linked to this GitLab project.
* `issues_url` The URL to the issue in Redmine project that is linked to this GitLab project. Note that the `issues_url` requires `:id` in the url. This id GitLab uses as a placeholder to replace the issue number.
* `new_issue_url` This is the URL to create a new issue in Redmine for the project linked to this GitLab project.


### Service Template

Since external issue tracker needs some project specific details, it is required to enable issue tracker per project level.
GitLab makes this easier by allowing admin to add a service template which will allow GitLab project user with permissions to edit details for its project.

In GitLab Admin section, navigate to `Service Templates` and choose the service template you want to create:

![redmine service template](redmine_service_template.png)

After the template is created, the template details will be pre-filled on the project service page.

Support to add your commits to the Jira ticket automatically is [available in GitLab EE](http://doc.gitlab.com/ee/integration/jira.html).
