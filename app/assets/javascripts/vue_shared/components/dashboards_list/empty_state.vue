<script>
import { GlEmptyState } from '@gitlab/ui';
import EMPTY_DASHBOARD_SVG from '@gitlab/svgs/dist/illustrations/empty-state/empty-dashboard-md.svg';
import { s__ } from '~/locale';

export default {
  name: 'DashboardsListEmptyState',
  components: {
    GlEmptyState,
  },
  i18n: {
    title: s__('AnalyticsDashboards|No dashboards found'),
  },
  emptySvgPath: EMPTY_DASHBOARD_SVG,
};
</script>
<template>
  <gl-empty-state :title="$options.i18n.title" :svg-path="$options.emptySvgPath" />
</template>
