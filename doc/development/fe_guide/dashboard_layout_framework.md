---
stage: Monitor
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Dashboard layout framework
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/191174) in GitLab 18.1.

{{< /history >}}

The dashboard layout framework is part of a broader effort to standardize dashboards across the platform
as described in [Epic #13801](https://gitlab.com/groups/gitlab-org/-/epics/13801).

For more in depth details on the dashboard layout framework, see the [architecture design document](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/dashboard_layout_framework/).

## Rendering dashboards

To render dashboard layouts it's recommended to use the [GlDashboardLayout](https://design.gitlab.com/storybook/?path=/docs/dashboards-dashboards-layout--docs)
component. It provides an easy way to render dashboards using
a configuration which aligns with our [Pajamas guidelines](https://design.gitlab.com/patterns/dashboards/).

Note that GlDashboardLayout supplants the deprecated `dashboard_layout.vue` component in the vue shared directory.

### Panel guidelines

You are free to
choose whichever panel component best suits your needs. However, to ensure consistency
with our design patterns, it's strongly recommended that you use one of the
following components:

- [GlDashboardPanel](https://gitlab-org.gitlab.io/gitlab-ui/?path=/docs/dashboards-dashboards-panel--docs): The official Pajamas dashboard panel
- [`extended_dashboard_panel.vue`](https://gitlab-org.gitlab.io/gitlab/storybook/?path=/docs/vue-shared-components-extended-dashboard-panel--docs): Extends `GlDashboardPanel` with easy alert styling and i18n strings

## Migration guide

Migrating an existing dashboard to the GlDashboardLayout should be relatively
straightforward. In most cases because you only need to replace the dashboard shell
and can keep existing visualizations. A typical migration path could look like this:

1. Create a feature flag to conditionally render your new dashboard.
1. Create a new dashboard using GlDashboardLayout and `extended_dashboard_panel.vue`.
1. Create a dashboard config object that mimics your old dashboard layout.
1. Optionally, use GlDashboardLayout's slots to render your dashboard's
filters, actions, or custom title or description.
1. Ensure your new dashboard, panels, and visualizations render correctly.
1. Remove the feature flag and your old dashboard.

See the basic implementation on [GitLab UI](https://design.gitlab.com/storybook/?path=/docs/dashboards-dashboards-layout--docs)
for an example on how to render existing visualization components using the dashboard layout component.

### Example implementations

Real world implementations and migrations using the GlDashboardLayout component:

- New security dashboard added in MR [!191974](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/191974)
