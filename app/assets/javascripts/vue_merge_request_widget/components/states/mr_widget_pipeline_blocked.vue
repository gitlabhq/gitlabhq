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
    <status-icon
      status="warning"
      :show-disabled-button="true"
    />
    <div class="media-body space-children">
      <span class="bold">
        {{ s__(`mrWidget|Pipeline blocked.
The pipeline for this merge request requires a manual action to proceed`) }}
      </span>
    </div>
  </div>
</template>
