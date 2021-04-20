---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Service templates **(FREE)**

WARNING:
Service templates are [deprecated and scheduled to be removed](https://gitlab.com/gitlab-org/gitlab/-/issues/268032)
in GitLab 14.0. Use [project integration management](#central-administration-of-project-integrations) instead.

Using a service template, GitLab administrators can:

- Provide default values for configuring integrations when creating new projects.
- Bulk configure all existing projects in one step.

When you enable a service template:

- The defaults are applied to **all** existing projects that either:
  - Don't already have the integration enabled.
  - Don't have custom values stored for already enabled integrations.
- Values are populated on each project's configuration page for the applicable
  integration.
- Settings are stored at the project level.

If you disable the template:

- GitLab default values again become the default values for integrations on
  new projects.
- Projects previously configured using the template continue to use those settings.

If you change the template, the revised values are applied to new projects. This feature
does not provide central administration of integration settings.

## Central administration of project integrations

A new set of features is being introduced in GitLab to provide more control over
how integrations are configured at the instance, group, and project level. For
more information, read more about:

- [Setting up project integration management](../../admin_area/settings/project_integration_management.md) (introduced in GitLab 13.3)
- [Our plans for managing integrations](https://gitlab.com/groups/gitlab-org/-/epics/2137).

## Enable a service template

Navigate to the **Admin Area > Service Templates** and choose the service
template you wish to create.

Recommendation:

- Test the settings on some projects individually before enabling a template.
- Copy the working settings from a project to the template.

There is no "Test settings" option when enabling templates. If the settings do not work,
these incorrect settings are applied to all existing projects that do not already have
the integration configured. Fixing the integration then needs to be done project-by-project.

## Service for external issue trackers

The following image shows an example service template for Redmine.

![Redmine service template](img/services_templates_redmine_example.png)

For each project, you still need to configure the issue tracking
URLs by replacing `:issues_tracker_id` in the above screenshot with the ID used
by your external issue tracker.
