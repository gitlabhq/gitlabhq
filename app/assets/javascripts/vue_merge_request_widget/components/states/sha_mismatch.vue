<script>
import statusIcon from '../mr_widget_status_icon.vue';

export default {
  name: 'ShaMismatch',
  components: {
    statusIcon,
  },
};
</script>

<template>
  <div class="mr-widget-body media">
    <status-icon :show-disabled-button="true" status="warning" />
    <div class="media-body space-children">
      <span class="bold">
        {{
          s__(`mrWidget|The source branch HEAD has recently changed.
Please reload the page and review the changes before merging`)
        }}
      </span>
    </div>
  </div>
</template>
