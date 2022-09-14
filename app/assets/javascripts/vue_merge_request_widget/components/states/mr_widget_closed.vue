<script>
import MrWidgetAuthorTime from '../mr_widget_author_time.vue';
import StateContainer from '../state_container.vue';

export default {
  name: 'MRWidgetClosed',
  components: {
    MrWidgetAuthorTime,
    StateContainer,
  },
  props: {
    mr: {
      type: Object,
      required: true,
    },
  },
};
</script>
<template>
  <state-container :mr="mr" status="closed">
    <mr-widget-author-time
      :action-text="s__('mrWidget|Closed by')"
      :author="mr.metrics.closedBy"
      :date-title="mr.metrics.closedAt"
      :date-readable="mr.metrics.readableClosedAt"
    />
  </state-container>
</template>
