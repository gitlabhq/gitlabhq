# YouTrack Service

JetBrains [YouTrack](https://www.jetbrains.com/help/youtrack/standalone/YouTrack-Documentation.html) is a web-based issue tracking and project management platform.

You can configure YouTrack as an [External Issue Tracker](../../../integration/external-issue-tracker.md) in GitLab.

## Enable the YouTrack integration in a project

Navigate to the [Integrations page](project_services.md#accessing-the-project-services), click
the **YouTrack** service, and enter the required details on the page as described
in the table below.

    | Field | Description |
    | ----- | ----------- |
    | `description`   | A name for the issue tracker (to differentiate between instances, for example) |
    | `project_url`   | The URL to the project in YouTrack which is being linked to this GitLab project |
    | `issues_url`    | The URL to the issue in YouTrack project that is linked to this GitLab project. Note that the `issues_url` requires `:id` in the URL. This ID is used by GitLab as a placeholder to replace the issue number. |

Once you have configured and enabled YouTrack you'll see the YouTrack link on the GitLab project pages that takes you to the appropriate YouTrack project.

## Disable the internal issue tracker in a project

Navigate to the General page, expand [Permissions](../settings/index.md#sharing-and-permissions), and switch the Issues toggle to disabled.

![Issue configuration](img/issue_configuration.png)

## Referencing YouTrack issues in GitLab

Issues in YouTrack can be referenced as `<PROJECT>-<ID>`. `<PROJECT>`
must start with a capital letter and can then be followed by capital or lower case
letters, numbers or underscores. `<ID>` is a number. An example reference is `YT-101` or `Api_32-143`.

References to <PROJECT>-<ID> in merge requests, commits, or comments are automatically linked to the YouTrack issue URL.
For more information, see the [External Issue Tracker](../../../integration/external-issue-tracker.md) documentation.
