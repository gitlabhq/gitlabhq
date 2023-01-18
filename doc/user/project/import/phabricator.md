---
type: howto
stage: Manage
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Import Phabricator tasks into a GitLab project (deprecated) **(FREE SELF)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/60562) in GitLab 12.0.

WARNING:
The Phabricator task importer was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/106369) in GitLab 15.7
and will be removed in GitLab 16.0.

WARNING:
The Phabricator task importer is in
[beta](../../../policy/alpha-beta-support.md#beta-features) and is
[**not** complete](https://gitlab.com/gitlab-org/gitlab/-/issues/284406). It imports
only an issue's title and description. The GitLab project created during the import
process contains only issues, and the associated repository is disabled.

GitLab allows you to import all tasks from a Phabricator instance into
GitLab issues. The import creates a single project with the
repository disabled.

Only the following basic fields are imported:

- Title
- Description
- State (open or closed)
- Created at
- Closed at

## Users

The assignee and author of a user are deducted from a Task's owner and
author: If a user with the same username has access to the namespace
of the project being imported into, then the user will be linked.

## Enable this feature

Enable Phabricator as an [import source](../../admin_area/settings/visibility_and_access_controls.md#configure-allowed-import-sources) in the Admin Area.
