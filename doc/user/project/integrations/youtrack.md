# YouTrack Service

JetBrains [YouTrack](https://www.jetbrains.com/help/youtrack/standalone/YouTrack-Documentation.html) is a web-based issue tracking and project management platform.

You can configure YouTrack as an [External Issue Tracker](../../../integration/external-issue-tracker.md) in GitLab.

## Enable the YouTrack integration

To enable YouTrack integration in a project:

1. Navigate to the project's **Settings > [Integrations](project_services.md#accessing-the-project-services)** page.
1. Click the **YouTrack** service, ensure it's active, and enter the required details on the page as described in the table below.

    | Field           | Description                                                                                                                                                                                                 |
    |:----------------|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
    | **Description** | Name for the issue tracker (to differentiate between instances, for example).                                                                                                                               |
    | **Project url** | URL to the project in YouTrack which is being linked to this GitLab project.                                                                                                                                |
    | **Issues url**  | URL to the issue in YouTrack project that is linked to this GitLab project. Note that the **Issues url** requires `:id` in the URL. This ID is used by GitLab as a placeholder to replace the issue number. |

1. Click the **Save changes** button.

Once you have configured and enabled YouTrack, you'll see the YouTrack link on the GitLab project pages that takes you to the appropriate YouTrack project.

## Disable the internal issue tracker

To disable the internal issue tracker in a project:

1. Navigate to the project's **Settings > General** page.
1. Expand the [permissions section](../settings/index.md#sharing-and-permissions) and switch the **Issues** toggle to disabled.

## Referencing YouTrack issues in GitLab

Issues in YouTrack can be referenced as `<PROJECT>-<ID>`. `<PROJECT>`
must start with a letter and is followed by letters, numbers, or underscores.
`<ID>` is a number. An example reference is `YT-101`, `Api_32-143` or `gl-030`.

References to `<PROJECT>-<ID>` in merge requests, commits, or comments are automatically linked to the YouTrack issue URL.
For more information, see the [External Issue Tracker](../../../integration/external-issue-tracker.md) documentation.
