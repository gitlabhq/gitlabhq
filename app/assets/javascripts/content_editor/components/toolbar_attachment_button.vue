<script>
import { GlButton, GlTooltipDirective as GlTooltip } from '@gitlab/ui';
import Link from '../extensions/link';

export default {
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
  <span class="gl-display-inline-flex">
    <gl-button
      v-gl-tooltip
      :text="__('Attach a file or image')"
      :title="__('Attach a file or image')"
      category="tertiary"
      icon="paperclip"
      size="small"
      lazy
      @click="openFileUpload"
    />
    <input
      ref="fileSelector"
      type="file"
      multiple
      name="content_editor_image"
      class="gl-display-none"
      data-qa-selector="file_upload_field"
      @change="onFileSelect"
    />
  </span>
</template>
