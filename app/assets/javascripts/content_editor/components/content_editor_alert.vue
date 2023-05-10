<script>
import { GlAlert } from '@gitlab/ui';
import EditorStateObserver from './editor_state_observer.vue';

export default {
  components: {
    GlAlert,
    EditorStateObserver,
  },
  data() {
    return {
      message: null,
      variant: 'danger',
    };
  },
  methods: {
    displayAlert({ message, variant, action, actionLabel }) {
      this.message = message;
      this.variant = variant;
      this.action = action;
      this.actionLabel = actionLabel;
    },
    dismissAlert() {
      this.message = null;
    },
    primaryAction() {
      this.dismissAlert();
      this.action?.();
    },
  },
};
</script>
<template>
  <editor-state-observer @alert="displayAlert">
    <gl-alert
      v-if="message"
      :variant="variant"
      :primary-button-text="actionLabel"
      @dismiss="dismissAlert"
      @primaryAction="primaryAction"
    >
      {{ message }}
    </gl-alert>
  </editor-state-observer>
</template>
