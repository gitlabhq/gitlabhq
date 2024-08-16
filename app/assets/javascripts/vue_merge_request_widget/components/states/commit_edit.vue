<script>
import { GlFormTextarea } from '@gitlab/ui';

export default {
  components: {
    GlFormTextarea,
  },
  model: {
    prop: 'value',
    event: 'input',
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
};
</script>

<template>
  <li>
    <div class="commit-message-editor">
      <div class="justify-content-between gl-mb-3 gl-flex gl-flex-wrap gl-items-center">
        <label class="col-form-label" :for="inputId">
          <strong>{{ label }}</strong>
        </label>
        <slot name="header"></slot>
      </div>
      <gl-form-textarea
        :id="inputId"
        :value="value"
        class="form-control js-gfm-input commit-message-edit gl-mb-3 !gl-font-monospace"
        dir="auto"
        required="required"
        rows="7"
        max-rows="32"
        no-resize
        @input="(val) => $emit('input', val)"
      />
    </div>
  </li>
</template>
