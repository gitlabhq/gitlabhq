<script>
import StatusIcon from '../mr_widget_status_icon.vue';

export default {
  name: 'MRWidgetArchived',
  components: {
    StatusIcon,
  },
};
</script>
<template>
  <div class="mr-widget-body media">
    <div class="space-children">
      <status-icon status="warning" show-disabled-button />
    </div>
    <div class="media-body">
      <span class="gl-ml-0! gl-text-body! bold">
        {{ s__('mrWidget|Merge unavailable: merge requests are read-only on archived projects.') }}
      </span>
    </div>
  </div>
</template>
