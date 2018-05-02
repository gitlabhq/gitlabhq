<script>
import statusIcon from '../mr_widget_status_icon.vue';

export default {
  name: 'PipelineFailed',
  components: {
    statusIcon,
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
        {{ s__(`mrWidget|The pipeline for this merge request failed.
Please retry the job or push a new commit to fix the failure`) }}
      </span>
    </div>
  </div>
</template>
