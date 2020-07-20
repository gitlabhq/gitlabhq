<script>
import statusIcon from '../mr_widget_status_icon.vue';

export default {
  name: 'MRWidgetChecking',
  components: {
    statusIcon,
  },
};
</script>
<template>
  <div class="mr-widget-body media">
    <status-icon :show-disabled-button="true" status="loading" />
    <div class="media-body space-children">
      <span class="bold"> {{ s__('mrWidget|Checking if merge request can be merged…') }} </span>
    </div>
  </div>
</template>
