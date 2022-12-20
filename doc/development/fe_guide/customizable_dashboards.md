---
stage: Analytics
group: Product Analytics
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Customizable dashboards **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/98610) in GitLab 15.5 as an [Alpha feature](../../policy/alpha-beta-support.md#alpha-features).

Customizable dashboards provide a dashboard structure that allows users to create
their own dashboards and commit the structure to a repository.

## Usage

To use customizable dashboards:

1. Create your dashboard component.
1. Render an instance of `CustomizableDashboard`.
1. Pass a list of widgets to render.

For example, a customizable dashboard for users over time:

```vue
<script>
import CustomizableDashboard from 'ee/vue_shared/components/customizable_dashboard/customizable_dashboard.vue';
import { s__ } from '~/locale';

export default {
  name: 'AnalyticsDashboard',
  components: {
    CustomizableDashboard,
  },
  data() {
    return {
      widgets: [
        {
          component: 'CubeLineChart', // The name of the widget component.
          title: s__('ProductAnalytics|Users / Time'), // The title shown on the widget component.
          // Gridstack settings based upon https://github.com/gridstack/gridstack.js/tree/master/doc#item-options.
          // All values are grid row/column numbers up to 12.
          // We use the default 12 column grid https://github.com/gridstack/gridstack.js#change-grid-columns.
          gridAttributes: {
            height: 4,
            width: 6,
            minHeight: 4,
            minWidth: 6,
            xPos: 0,
            yPos: 0,
          },
          // Options that are used to set bespoke values for each widget.
          // Available customizations are determined by the widget itself.
          customizations: {},
          // Chart options defined by the charting library being used by the widget.
          chartOptions: {
            xAxis: { name: __('Time'), type: 'time' },
            yAxis: { name: __('Counts') },
          },
          // The data for the widget.
          // This could be imported or in this case, a query passed to be used by the widgets API.
          // Each widget type determines how it handles this property.
          data: {
            query: {
              users: {
                measures: ['Jitsu.count'],
                dimensions: ['Jitsu.eventType'],
              },
            },
          },
        },
      ]
    };
  },
};
</script>

<template>
  <h1>{{ s__('ProductAnalytics|Analytics dashboard') }}</h1>
  <customizable-dashboard :widgets="widgets" />
</template>
```

The widgets data can be retrieved from a file or API request, or imported through HTML data attributes.

For each widget, a `component` is defined. Each `component` is a component declaration and should be included in
[`vue_shared/components/customizable_dashboard/widgets_base.vue`](https://gitlab.com/gitlab-org/gitlab/blob/master/ee/app/assets/javascripts/vue_shared/components/customizable_dashboard/widgets_base.vue)
as a dynamic import, to keep the memory usage down until it is used.

For example:

```javascript
components: {
  CubeLineChart: () => import('ee/product_analytics/dashboards/components/widgets/cube_line_chart.vue')
}
```
