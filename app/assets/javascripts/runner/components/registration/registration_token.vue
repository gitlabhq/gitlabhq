<script>
import { s__ } from '~/locale';
import InputCopyToggleVisibility from '~/vue_shared/components/form/input_copy_toggle_visibility.vue';

export default {
  components: {
    InputCopyToggleVisibility,
  },
  props: {
    value: {
      type: String,
      required: false,
      default: '',
    },
  },
  methods: {
    onCopy() {
      // value already in the clipboard, simply notify the user
      this.$toast?.show(s__('Runners|Registration token copied!'));
    },
  },
  I18N_COPY_BUTTON_TITLE: s__('Runners|Copy registration token'),
};
</script>
<template>
  <input-copy-toggle-visibility
    class="gl-m-0"
    :value="value"
    data-testid="token-value"
    :copy-button-title="$options.I18N_COPY_BUTTON_TITLE"
    @copy="onCopy"
  />
</template>
