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
  <div class="content-editor-switcher gl-inline-flex gl-items-center">
    <gl-button
      :id="$options.richTextEditorButtonId"
      size="small"
      category="tertiary"
      class="!gl-px-4 !gl-text-sm !gl-text-subtle"
      data-testid="editing-mode-switcher"
      @click="$emit('switch')"
      >{{ text }}</gl-button
    >
  </div>
</template>
