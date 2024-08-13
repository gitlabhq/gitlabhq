<script>
import { GlButton, GlTooltipDirective as GlTooltip } from '@gitlab/ui';
import { __ } from '~/locale';
import Link from '../extensions/link';

export default {
  i18n: {
    inputLabel: __('Attach a file or image'),
  },
  components: {
    GlButton,
  },
  directives: {
    GlTooltip,
  },
  inject: ['tiptapEditor'],
  data() {
    return {
      linkHref: '',
    };
  },
  methods: {
    emitExecute(source = 'url') {
      this.$emit('execute', { contentType: Link.name, value: source });
    },
    openFileUpload() {
      this.$refs.fileSelector.click();
    },
    onFileSelect(e) {
      for (const file of e.target.files) {
        this.tiptapEditor.chain().focus().uploadAttachment({ file }).run();
      }

      // Reset the file input so that the same file can be uploaded again
      this.$refs.fileSelector.value = '';
      this.emitExecute('upload');
    },
  },
};
</script>
<template>
  <span class="gl-inline-flex">
    <gl-button
      v-gl-tooltip
      :aria-label="$options.i18n.inputLabel"
      :title="$options.i18n.inputLabel"
      category="tertiary"
      icon="paperclip"
      size="small"
      class="gl-mr-2"
      lazy
      @click="openFileUpload"
    />
    <input
      ref="fileSelector"
      type="file"
      multiple
      name="content_editor_image"
      class="gl-hidden"
      :aria-label="$options.i18n.inputLabel"
      data-testid="file-upload-field"
      @change="onFileSelect"
    />
  </span>
</template>
