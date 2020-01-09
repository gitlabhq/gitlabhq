# Import Phabricator tasks into a GitLab project

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/issues/60562) in
GitLab 12.0.

GitLab allows you to import all tasks from a Phabricator instance into
GitLab issues. The import creates a single project with the
repository disabled.

Currently, only the following basic fields are imported:

- Title
- Description
- State (open or closed)
- Created at
- Closed at

## Users

The assignee and author of a user are deducted from a Task's owner and
author: If a user with the same username has access to the namespace
of the project being imported into, then the user will be linked.

## Enabling this feature

While this feature is incomplete, a feature flag is required to enable it so that
we can gain early feedback before releasing it for everyone. To enable it:

1. Run the following command in a Rails console:

   ```ruby
   Feature.enable(:phabricator_import)
   ```

1. Enable Phabricator as an [import source](../../admin_area/settings/visibility_and_access_controls.md#import-sources) in the Admin Area.
