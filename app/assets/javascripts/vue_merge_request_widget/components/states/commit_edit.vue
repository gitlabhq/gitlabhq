<script>
export default {
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
      <div class="d-flex gl-flex-wrap gl-align-items-center justify-content-between gl-mb-3">
        <label class="col-form-label" :for="inputId">
          <strong>{{ label }}</strong>
        </label>
        <slot name="header"></slot>
      </div>
      <textarea
        :id="inputId"
        :value="value"
        class="form-control js-gfm-input gl-mb-3 commit-message-edit"
        dir="auto"
        required="required"
        rows="7"
        @input="$emit('input', $event.target.value)"
      ></textarea>
    </div>
  </li>
</template>
