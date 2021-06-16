<script>
import { GlLink, GlAlert } from '@gitlab/ui';

export default {
  name: 'MRWidgetAlertMessage',
  components: {
    GlAlert,
    GlLink,
  },
  props: {
    type: {
      type: String,
      required: true,
    },
    helpPath: {
      type: String,
      required: false,
      default: undefined,
    },
    dismissible: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isDismissed: false,
    };
  },
  methods: {
    onDismiss() {
      this.isDismissed = true;
    },
  },
};
</script>

<template>
  <gl-alert v-if="!isDismissed" :variant="type" :dismissible="dismissible" @dismiss="onDismiss">
    <slot></slot>
    <gl-link v-if="helpPath" :href="helpPath" target="_blank" class="gl-label-link">
      <slot name="link-content"></slot>
    </gl-link>
  </gl-alert>
</template>
