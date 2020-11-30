<script>
import { GlDropdown, GlDropdownForm, GlFormTextarea, GlButton } from '@gitlab/ui';
import { __, sprintf } from '~/locale';

export default {
  components: { GlDropdown, GlDropdownForm, GlFormTextarea, GlButton },
  props: {
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    fileName: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      message: null,
      buttonText: __('Apply suggestion'),
      headerText: __('Apply suggestion commit message'),
    };
  },
  computed: {
    placeholderText() {
      return sprintf(__('Apply suggestion on %{fileName}'), { fileName: this.fileName });
    },
  },
  methods: {
    onApply() {
      this.$emit('apply', this.message || this.placeholderText);
    },
  },
};
</script>

<template>
  <gl-dropdown
    :text="buttonText"
    :header-text="headerText"
    :disabled="disabled"
    boundary="window"
    right="true"
    menu-class="gl-w-full! gl-pb-0!"
  >
    <gl-dropdown-form class="gl-m-3!">
      <gl-form-textarea v-model="message" :placeholder="placeholderText" />
      <gl-button
        class="gl-w-quarter! gl-mt-3 gl-text-center! float-right"
        category="secondary"
        variant="success"
        @click="onApply"
      >
        {{ __('Apply') }}
      </gl-button>
    </gl-dropdown-form>
  </gl-dropdown>
</template>
