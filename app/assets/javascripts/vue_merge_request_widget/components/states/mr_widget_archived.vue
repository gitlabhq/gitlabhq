<script>
import { GlButton } from '@gitlab/ui';
import statusIcon from '../mr_widget_status_icon.vue';

export default {
  name: 'MRWidgetArchived',
  components: {
    GlButton,
    statusIcon,
  },
};
</script>
<template>
  <div class="mr-widget-body media">
    <div class="space-children">
      <status-icon status="warning" />
      <gl-button category="secondary" variant="success" :disabled="true">
        {{ s__('mrWidget|Merge') }}
      </gl-button>
    </div>
    <div class="media-body">
      <span class="bold">
        {{ s__('mrWidget|This project is archived, write access has been disabled') }}
      </span>
    </div>
  </div>
</template>
