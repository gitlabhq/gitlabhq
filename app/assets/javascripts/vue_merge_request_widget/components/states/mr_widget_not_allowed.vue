<script>
import StatusIcon from '../mr_widget_status_icon.vue';

export default {
  name: 'MRWidgetNotAllowed',
  components: {
    StatusIcon,
  },
};
</script>

<template>
  <div class="mr-widget-body media">
    <status-icon status="success" />
    <div class="media-body space-children">
      <span class="gl-font-weight-bold">
        {{
          s__(`mrWidget|Ready to be merged automatically.
Ask someone with write access to this repository to merge this request`)
        }}
      </span>
    </div>
  </div>
</template>
