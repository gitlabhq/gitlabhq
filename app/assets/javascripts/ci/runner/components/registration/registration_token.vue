<script>
import { s__ } from '~/locale';
import InputCopyToggleVisibility from '~/vue_shared/components/input_copy_toggle_visibility/input_copy_toggle_visibility.vue';

export default {
  components: {
    InputCopyToggleVisibility,
  },
  i18n: {
    registrationToken: s__('Runners|Registration token'),
  },
  props: {
    inputId: {
      type: String,
      required: true,
    },
    value: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    formInputGroupProps() {
      return {
        id: this.inputId,
      };
    },
  },
  methods: {
    onCopy() {
      // value already in the clipboard, simply notify the user
      this.$toast?.show(s__('Runners|Registration token copied!'));
      this.$emit('copy');
    },
  },
  I18N_COPY_BUTTON_TITLE: s__('Runners|Copy registration token'),
};
</script>
<template>
  <input-copy-toggle-visibility
    class="gl-m-0"
    :value="value"
    :label="$options.i18n.registrationToken"
    :label-for="inputId"
    :copy-button-title="$options.I18N_COPY_BUTTON_TITLE"
    :form-input-group-props="formInputGroupProps"
    readonly
    @copy="onCopy"
  >
    <template v-for="slot in Object.keys($scopedSlots)" #[slot]>
      <slot :name="slot"></slot>
    </template>
  </input-copy-toggle-visibility>
</template>
