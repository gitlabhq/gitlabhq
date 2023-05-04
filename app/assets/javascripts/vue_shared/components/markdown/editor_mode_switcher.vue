<script>
import { GlButton } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlButton,
  },
  props: {
    value: {
      type: String,
      required: true,
    },
  },
  computed: {
    markdownEditorSelected() {
      return this.value === 'markdown';
    },
    text() {
      return this.markdownEditorSelected ? __('Switch to rich text') : __('Switch to Markdown');
    },
  },
};
</script>
<template>
  <gl-button
    class="btn btn-default btn-sm gl-button btn-default-tertiary"
    data-qa-selector="editing_mode_switcher"
    @click="$emit('input')"
    >{{ text }}</gl-button
  >
</template>
