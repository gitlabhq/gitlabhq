<script>
import { GlLoadingIcon, GlButton } from '@gitlab/ui';
import eventHub from '../../event_hub';
import statusIcon from '../mr_widget_status_icon.vue';

export default {
  name: 'MRWidgetAutoMergeFailed',
  components: {
    statusIcon,
    GlLoadingIcon,
    GlButton,
  },
  props: {
    mr: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isRefreshing: false,
    };
  },
  methods: {
    refreshWidget() {
      this.isRefreshing = true;
      eventHub.$emit('MRWidgetUpdateRequested', () => {
        this.isRefreshing = false;
      });
    },
  },
};
</script>
<template>
  <div class="mr-widget-body media">
    <status-icon status="warning" />
    <div class="media-body space-children gl-display-flex gl-flex-wrap gl-align-items-center">
      <span class="bold">
        <template v-if="mr.mergeError">{{ mr.mergeError }}</template>
        {{ s__('mrWidget|This merge request failed to be merged automatically') }}
      </span>
      <gl-button
        :disabled="isRefreshing"
        category="secondary"
        variant="default"
        size="small"
        @click="refreshWidget"
      >
        <gl-loading-icon v-if="isRefreshing" :inline="true" />
        {{ s__('mrWidget|Refresh') }}
      </gl-button>
    </div>
  </div>
</template>
