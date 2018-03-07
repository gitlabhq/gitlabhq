# Custom Issue Tracker Service

To enable the Custom Issue Tracker integration in a project, navigate to the
[Integrations page](project_services.md#accessing-the-project-services), click
the **Customer Issue Tracker** service, and fill in the required details on the page as described
in the table below.

| Field | Description |
| ----- | ----------- |
| `title`   | A title for the issue tracker (to differentiate between instances, for example) |
| `description`   | A name for the issue tracker (to differentiate between instances, for example) |
| `project_url`   | Currently unused. Will be changed in a future release. |
| `issues_url`    | The URL to the issue in the issue tracker project that is linked to this GitLab project. Note that the `issues_url` requires `:id` in the URL. This ID is used by GitLab as a placeholder to replace the issue number. For example, `https://customissuetracker.com/project-name/:id`. |
| `new_issue_url` | Currently unused. Will be changed in a future release. |

Once you have configured and enabled Custom Issue Tracker Service you'll see a link on the GitLab project pages that takes you to that custom issue tracker.


## Referencing issues

Issues are referenced with `#<ID>`, where `<ID>` is a number (example `#143`). 
So with the example above, `#143` would refer to `https://customissuetracker.com/project-name/143`.