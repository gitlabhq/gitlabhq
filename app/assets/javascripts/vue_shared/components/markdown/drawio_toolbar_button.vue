<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { launchDrawioEditor } from '~/drawio/drawio_editor';
import { create } from '~/drawio/markdown_field_editor_facade';

export default {
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    uploadsPath: {
      type: String,
      required: true,
    },
    markdownPreviewPath: {
      type: String,
      required: true,
    },
  },
  methods: {
    getTextArea() {
      return document.querySelector('.js-gfm-input');
    },
    launchDrawioEditor() {
      launchDrawioEditor({
        editorFacade: create({
          uploadsPath: this.uploadsPath,
          textArea: this.getTextArea(),
          markdownPreviewPath: this.markdownPreviewPath,
        }),
      });
    },
  },
};
</script>
<template>
  <gl-button
    v-gl-tooltip
    :title="__('Insert or edit diagram')"
    :aria-label="__('Insert or edit diagram')"
    category="tertiary"
    icon="diagram"
    size="small"
    @click="launchDrawioEditor"
  />
</template>
