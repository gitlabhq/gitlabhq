<!-- eslint-disable vue/multi-word-component-names -->
<script>
import InputCopyToggleVisibility from '~/vue_shared/components/form/input_copy_toggle_visibility.vue';

export default {
  components: { InputCopyToggleVisibility },
  props: {
    token: {
      type: String,
      required: true,
    },
    inputId: {
      type: String,
      required: true,
    },
    inputLabel: {
      type: String,
      required: true,
    },
    copyButtonTitle: {
      type: String,
      required: true,
    },
    size: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    formInputGroupProps() {
      return { id: this.inputId };
    },
  },
};
</script>

<template>
  <div>
    <h4 class="gl-my-0"><slot name="title"></slot></h4>
    <slot name="description"></slot>
    <input-copy-toggle-visibility
      :label="inputLabel"
      :label-for="inputId"
      :form-input-group-props="formInputGroupProps"
      :value="token"
      :copy-button-title="copyButtonTitle"
      readonly
      :size="size"
    >
      <template #description>
        <slot name="input-description"></slot>
      </template>
    </input-copy-toggle-visibility>
  </div>
</template>
