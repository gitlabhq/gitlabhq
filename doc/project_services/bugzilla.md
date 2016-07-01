# Bugzilla Service

Go to your project's **Settings > Services > Bugzilla** and fill in the required
details as described in the table below.

| Field | Description |
| ----- | ----------- |
| `description`   | A name for the issue tracker (to differentiate between instances, for example) |
| `project_url`   | The URL to the project in Bugzilla which is being linked to this GitLab project. Note that the `project_url` requires PRODUCT_NAME to be updated with the product/project name in Bugzilla. |
| `issues_url`    | The URL to the issue in Bugzilla project that is linked to this GitLab project. Note that the `issues_url` requires `:id` in the URL. This ID is used by GitLab as a placeholder to replace the issue number. |
| `new_issue_url` | This is the URL to create a new issue in Bugzilla for the project linked to this GitLab project. Note that the `new_issue_url` requires PRODUCT_NAME to be updated with the product/project name in Bugzilla. |

Once you have configured and enabled Bugzilla:

- the **Issues** link on the GitLab project pages takes you to the appropriate
  Bugzilla product page
- clicking **New issue** on the project dashboard takes you to Bugzilla for entering a new issue
