---
stage: Data Stores
group: Tenant Scale
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Groups **(FREE)**

In GitLab, you use groups to manage one or more related projects at the same time.

You can use groups to manage permissions for your projects. If someone has access to
the group, they get access to all the projects in the group.

You can also view all of the issues and merge requests for the projects in the group,
and view analytics that show the group's activity.

You can use groups to communicate with all of the members of the group at once.

For larger organizations, you can also create [subgroups](subgroups/index.md).

For more information about creating and managing your groups, see [Manage groups](manage.md).

NOTE:
Self-managed customers should create a top-level group so you can see an overview of
your organization. For more information about efforts to create an
organization view of all groups, [see epic 9266](https://gitlab.com/groups/gitlab-org/-/epics/9266).
A top-level group can also have one complete
[Security Dashboard and Center](../application_security/security_dashboard/index.md),
[Vulnerability](../application_security/vulnerability_report/index.md#vulnerability-report) and
[Compliance Report](../compliance/compliance_report/index.md), and
[Value stream analytics](../group/value_stream_analytics/index.md).

## Group visibility

Like projects, a group can be configured to limit the visibility of it to:

- Anonymous users.
- All authenticated users.
- Only explicit group members.

The restriction for [visibility levels](../admin_area/settings/visibility_and_access_controls.md#restrict-visibility-levels)
on the application setting level also applies to groups. If set to internal, the explore page is
empty for anonymous users. The group page has a visibility level icon.

Administrator users cannot create a subgroup or project with a higher visibility level than that of
the immediate parent group.

## Related topics

- [Group wikis](../project/wiki/index.md)
- [Maximum artifacts size](../admin_area/settings/continuous_integration.md#maximum-artifacts-size).
- [Repositories analytics](repositories_analytics/index.md): View overall activity of all projects with code coverage.
- [Contribution analytics](contribution_analytics/index.md): View the contributions (pushes, merge requests,
  and issues) of group members.
- [Issue analytics](issues_analytics/index.md): View a bar chart of your group's number of issues per month.
- Use GitLab as a [dependency proxy](../packages/dependency_proxy/index.md) for upstream Docker images.
- [Epics](epics/index.md): Track groups of issues that share a theme.
- [Security Dashboard](../application_security/security_dashboard/index.md): View the vulnerabilities of all
  the projects in a group and its subgroups.
- [Insights](insights/index.md): Configure insights like triage hygiene, issues created/closed per a given period, and
  average time for merge requests to be merged.
- [Webhooks](../project/integrations/webhooks.md).
- [Kubernetes cluster integration](clusters/index.md).
- [Audit Events](../../administration/audit_events.md#group-events).
- [CI/CD minutes quota](../../ci/pipelines/cicd_minutes.md): Keep track of the CI/CD minute quota for the group.
- [Integrations](../admin_area/settings/project_integration_management.md).
- [Transfer a project into a group](../project/settings/index.md#transfer-a-project-to-another-namespace).
- [Share a project with a group](../project/members/share_project_with_groups.md): Give all group members access to the project at once.
- [Lock the sharing with group feature](access_and_permissions.md#prevent-a-project-from-being-shared-with-groups).
- [Enforce two-factor authentication (2FA)](../../security/two_factor_authentication.md#enforce-2fa-for-all-users-in-a-group): Enforce 2FA
  for all group members.
- Namespaces [API](../../api/namespaces.md) and [Rake tasks](../../raketasks/index.md).
- [Control access and visibility](../admin_area/settings/visibility_and_access_controls.md).
