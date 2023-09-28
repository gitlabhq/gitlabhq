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
      return this.markdownEditorSelected
        ? __('Switch to rich text editing')
        : __('Switch to plain text editing');
    },
  },
  richTextEditorButtonId: 'switch-to-rich-text-editor',
};
</script>
<template>
  <div class="content-editor-switcher gl-display-inline-flex gl-align-items-center">
    <gl-button
      :id="$options.richTextEditorButtonId"
      class="btn btn-default btn-sm gl-button btn-default-tertiary gl-font-sm! gl-text-secondary! gl-px-4!"
      data-qa-selector="editing_mode_switcher"
      @click="$emit('switch')"
      >{{ text }}</gl-button
    >
  </div>
</template>
