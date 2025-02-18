<script>
import { GlLoadingIcon } from '@gitlab/ui';
import ReportWidgetContainer from 'ee_else_ce/vue_merge_request_widget/components/widget/app.vue';

export default {
  name: 'MergeRequestReportsIndexPage',
  components: {
    GlLoadingIcon,
    ReportWidgetContainer,
  },
  props: {
    mr: {
      type: Object,
      required: false,
      default: null,
    },
  },
};
</script>

<template>
  <div v-if="mr">
    <report-widget-container :mr="mr" reports-tab-content />
  </div>
  <gl-loading-icon v-else size="lg" />
</template>
