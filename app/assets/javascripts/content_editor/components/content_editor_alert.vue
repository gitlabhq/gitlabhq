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
    displayAlert({ message, variant }) {
      this.message = message;
      this.variant = variant;
    },
    dismissAlert() {
      this.message = null;
    },
  },
};
</script>
<template>
  <editor-state-observer @alert="displayAlert">
    <gl-alert v-if="message" class="gl-mb-6" :variant="variant" @dismiss="dismissAlert">
      {{ message }}
    </gl-alert>
  </editor-state-observer>
</template>
