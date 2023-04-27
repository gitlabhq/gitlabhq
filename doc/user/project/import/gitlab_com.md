---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Import a project from GitLab.com to your self-managed GitLab instance (deprecated) **(FREE)**

WARNING:
The GitLab.com importer was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/108502) in GitLab 15.8
and will be removed in GitLab 16.0. To import GitLab projects from GitLab.com to a self-managed GitLab instance use
[migrating groups and projects by direct transfer](../../group/import/index.md#migrate-groups-by-direct-transfer-recommended).

You can import your existing GitLab.com projects to your GitLab instance.

Prerequisite:

- GitLab.com integration must be enabled on your GitLab instance.
  [Read more about GitLab.com integration for self-managed GitLab instances](../../../integration/gitlab.md).

To import a GitLab.com project to your self-managed GitLab instance:

1. In GitLab, on the top bar, select **Main menu > Projects > View all projects**.
1. On the right of the page, select **New project**.
1. Select **Import project**.
1. Select **GitLab.com**.
1. Give GitLab.com permission to access your projects.
1. Select **Import**.

The importer imports your repository and issues.
When the importer is done, a new GitLab project is created with your imported data.

## Related topics

- [Automate group and project import](index.md#automate-group-and-project-import)
- [Export a project](../settings/import_export.md#export-a-project-and-its-data)
