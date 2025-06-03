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

The [`dashboard_layout.vue`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/vue_shared/components/customizable_dashboard/dashboard_layout.vue)
component provides an easy way to render dashboards using a configuration. This is
part of our broader effort to standardize dashboards across the platform
as described in [Epic #13801](https://gitlab.com/groups/gitlab-org/-/epics/13801).

For more in depth details on the dashboard layout framework, see the [architecture design document](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/dashboard_layout_framework/).

## Interactive examples

Try it in your browser using our interactive examples:

- [dashboard_layout](https://gitlab-org.gitlab.io/gitlab/storybook/?path=/docs/vue-shared-components-dashboard-layout--docs)
- [panels_base](https://gitlab-org.gitlab.io/gitlab/storybook/?path=/docs/vue-shared-components-panels-base--docs)

## When to use this component

This component should be used when:

- You want an easy way to create a dashboard interface.
- You want your dashboard to align with our [Pajamas guidelines](https://design.gitlab.com/patterns/dashboards).
- You want to benefit from future add-on features such as customizable layouts with resizable, draggable elements.

For existing dashboards, follow the [migration guide](#migration-guide) below.

## Current limitations

The component is limited to rendering dashboards. As defined in our architecture design document
it does not provide:

- Data exploration outside defined panel visualizations
- User-driven customization and management of dashboards
- Navigation placement for dashboards

While user customization is not supported yet, the foundation has been developed
and we plan to release an upgrade path from a static dashboard layout to a
customizable dashboard layout as part of GitLab issue [#546201](https://gitlab.com/gitlab-org/gitlab/-/issues/546201).

## The component

The `dashboard_layout.vue` component takes a dashboard configuration object as input
and renders a dashboard layout with title, description, actions, and panels in a
cross-browser 12-column grid system.

### Dashboard panels

The component is not opinionated about the panel component used. You are free to
choose whichever panel component best suits your needs. However, to ensure consistency
with our design patterns, it's strongly recommended that you use one of the
following components:

- [GlDashboardPanel](https://gitlab-org.gitlab.io/gitlab-ui/?path=/docs/dashboards-dashboards-panel--docs): The official Pajamas dashboard panel
- [`panels_base.vue`](https://gitlab-org.gitlab.io/gitlab/storybook/?path=/docs/vue-shared-components-panels-base--docs): Extends `GlDashboardPanel` with easy alert styling and i18n strings

### Filters

The component provides a `#filters` slot to render your filters in the dashboard
layout. The component does not manage or sync filters and leaves it up to the
consumer to manage this state.

We expect dashboards using the framework to implement two types of filters:

- Global filters: Applied to every visualization in the dashboard
- Per-panel filters: Applied to individual panels (future support planned)

For URL synchronization, you can use the shared [`UrlSync`](https://gitlab.com/gitlab-org/gitlab/blob/master/app/assets/javascripts/vue_shared/components/url_sync.vue) component.

### Additional slots

For a full list of supported slots see the [interactive examples](#interactive-examples).

### Basic implementation

```vue
<script>
// app/assets/javascripts/feature/components/dashboard.vue
import DashboardLayout from '~/vue_shared/components/customizable_dashboard/dashboard_layout.vue';
import PanelsBase from '~/vue_shared/components/customizable_dashboard/panels_base.vue';

import UsersVisualization from './my_users_visualization.vue';
import EventsVisualization from './my_events_visualization.vue';

export default {
  components: {
    DashboardLayout,
    PanelsBase,
    UsersVisualization,
    EventsVisualization,
  },
  data() {
    return {
      dashboard: {
        title: __('My dashboard title'),
        description: __('The dashboard description to render'),
        panels: [
          {
            id: '1',
            panelsBaseProps: {
              title: __('Active users over time'),
              // Any additional PanelsBase props go here
            },
            component: UsersVisualization,
            componentProps: {
              apiPath: '/example-users-api',
              // Any props you want to pass to your component
            },
            gridAttributes: {
              width: 6,
              height: 4,
              yPos: 0,
              xPos: 0,
            },
          },
          {
            id: '2',
            panelsBaseProps: {
              title:__('Events over time'),
              // Any additional PanelsBase props go here
            },
            component: EventsVisualization,
            componentProps: {
              apiPath: '/example-events-api',
              // Any props you want to pass to your component
            },
            gridAttributes: {
              width: 6,
              height: 4,
              yPos: 0,
              xPos: 6,
            },
          },
        ],
      },
    }
  },
}
</script>

<template>
  <dashboard-layout :config="dashboard">
    <template #panel="{ panel }">
      <panels-base v-bind="panel.panelsBaseProps">
        <template #body>
          <component
            :is="panel.component"
            class="gl-h-full gl-overflow-hidden"
            v-bind="panel.componentProps"
          />
        </template>
      </panels-base>
    </template>
  </dashboard-layout>
</template>
```

### Migration guide

Migrating an existing dashboard to the `dashboard_layout.vue` should be relatively
straightforward. In most cases because you only need to replace the dashboard shell
and can keep existing visualizations. A typical migration path could look like this:

1. Create a feature flag to conditionally render your new dashboard.
1. Create a new dashboard using `dashboard_layout.vue` and `panels_base.vue`.
1. Create a dashboard config object that mimics your old dashboard layout.
1. Optionally, use `dashboard_layout.vue`'s slots to render your dashboard's
filters, actions, or custom title or description.
1. Ensure your new dashboard, panels, and visualizations render correctly.
1. Remove the feature flag and your old dashboard.

See the [basic implementation](#basic-implementation) example above on how to render
existing visualization components using the dashboard layout component.

### Example implementations

Real world implementations and migrations using the `dashboard_layout.vue`
component:

- New security dashboard added in MR [!191974](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/191974)
