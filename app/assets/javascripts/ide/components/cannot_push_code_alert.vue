<script>
import { GlAlert, GlButton } from '@gitlab/ui';

export default {
  components: {
    GlAlert,
    GlButton,
  },
  props: {
    message: {
      type: String,
      required: true,
    },
    action: {
      type: Object,
      required: false,
      default: null,
    },
  },
  computed: {
    hasAction() {
      return Boolean(this.action?.href);
    },
    actionButtonMethod() {
      return this.action?.isForm ? 'post' : null;
    },
  },
};
</script>

<template>
  <gl-alert :dismissible="false">
    {{ message }}
    <template v-if="hasAction" #actions>
      <gl-button variant="confirm" :href="action.href" :data-method="actionButtonMethod">
        {{ action.text }}
      </gl-button>
    </template>
  </gl-alert>
</template>
