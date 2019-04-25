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
      <div class="d-flex flex-wrap align-items-center justify-content-between">
        <label class="col-form-label" :for="inputId">
          <strong>{{ label }}</strong>
        </label>
        <slot name="header"></slot>
      </div>
      <textarea
        :id="inputId"
        :value="value"
        class="form-control js-gfm-input append-bottom-default commit-message-edit"
        dir="auto"
        required="required"
        rows="7"
        @input="$emit('input', $event.target.value)"
      ></textarea>
      <slot name="checkbox"></slot>
    </div>
  </li>
</template>
