<script>
import StatusIcon from '../mr_widget_status_icon.vue';

export default {
  name: 'MRWidgetPipelineBlocked',
  components: {
    StatusIcon,
  },
};
</script>
<template>
  <div class="mr-widget-body media">
    <status-icon :show-disabled-button="true" status="warning" />
    <div class="media-body space-children">
      <span class="bold">
        {{
          s__(
            `mrWidget|Merge blocked: pipeline must succeed. It's waiting for a manual action to continue.`,
          )
        }}
      </span>
    </div>
  </div>
</template>
