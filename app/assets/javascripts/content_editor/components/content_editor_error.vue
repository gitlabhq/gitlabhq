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
      error: null,
    };
  },
  methods: {
    displayError({ error }) {
      this.error = error;
    },
    dismissError() {
      this.error = null;
    },
  },
};
</script>
<template>
  <editor-state-observer @error="displayError">
    <gl-alert v-if="error" class="gl-mb-6" variant="danger" @dismiss="dismissError">
      {{ error }}
    </gl-alert>
  </editor-state-observer>
</template>
