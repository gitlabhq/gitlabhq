<script>
import { GlButton, GlTooltipDirective as GlTooltip } from '@gitlab/ui';
import { Editor as TiptapEditor } from '@tiptap/vue-2';

export default {
  components: {
    GlButton,
  },
  directives: {
    GlTooltip,
  },
  props: {
    iconName: {
      type: String,
      required: true,
    },
    tiptapEditor: {
      type: TiptapEditor,
      required: true,
    },
    contentType: {
      type: String,
      required: true,
    },
    label: {
      type: String,
      required: true,
    },
    editorCommand: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    isActive() {
      return this.tiptapEditor.isActive(this.contentType) && this.tiptapEditor.isFocused;
    },
  },
  methods: {
    execute() {
      const { contentType } = this;

      if (this.editorCommand) {
        this.tiptapEditor.chain()[this.editorCommand]().focus().run();
      }

      this.$emit('execute', { contentType });
    },
  },
};
</script>
<template>
  <gl-button
    v-gl-tooltip
    category="tertiary"
    size="small"
    class="gl-mx-2"
    :class="{ active: isActive }"
    :aria-label="label"
    :title="label"
    :icon="iconName"
    @click="execute"
  />
</template>
