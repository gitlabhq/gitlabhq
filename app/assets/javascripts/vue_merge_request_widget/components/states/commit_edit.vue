<script>
import { GlFormTextarea } from '@gitlab/ui';

export default {
  components: {
    GlFormTextarea,
  },
  props: {
    value: {
      type: String,
      required: true,
    },
    label: {
      type: String,
      required: true,
    },
    inputId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      messageText: this.value,
    };
  },
};
</script>

<template>
  <li>
    <div class="commit-message-editor">
      <div
        class="gl-display-flex gl-flex-wrap gl-align-items-center justify-content-between gl-mb-3"
      >
        <label class="col-form-label" :for="inputId">
          <strong>{{ label }}</strong>
        </label>
        <slot name="header"></slot>
      </div>
      <gl-form-textarea
        :id="inputId"
        v-model="messageText"
        class="form-control js-gfm-input gl-mb-3 commit-message-edit !gl-font-monospace"
        dir="auto"
        required="required"
        rows="7"
        max-rows="32"
        @input="$emit('input', messageText)"
      />
    </div>
  </li>
</template>
