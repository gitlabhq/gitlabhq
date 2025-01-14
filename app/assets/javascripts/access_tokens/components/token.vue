<!-- eslint-disable vue/multi-word-component-names -->
<script>
import InputCopyToggleVisibility from '~/vue_shared/components/input_copy_toggle_visibility/input_copy_toggle_visibility.vue';
import SettingsSection from '~/vue_shared/components/settings/settings_section.vue';

export default {
  components: { InputCopyToggleVisibility, SettingsSection },
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
  <settings-section>
    <template #heading>
      <slot name="title"></slot>
    </template>
    <template #description>
      <slot name="description"></slot>
    </template>

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
        <div class="gl-mt-3">
          <slot name="input-description"></slot>
        </div>
      </template>
    </input-copy-toggle-visibility>
  </settings-section>
</template>
