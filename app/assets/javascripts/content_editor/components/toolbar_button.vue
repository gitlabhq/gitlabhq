<script>
import { GlButton, GlTooltipDirective as GlTooltip } from '@gitlab/ui';

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
    editor: {
      type: Object,
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
    executeCommand: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    isActive() {
      return this.editor.isActive[this.contentType]() && this.editor.focused;
    },
  },
  methods: {
    execute() {
      const { contentType } = this;

      if (this.executeCommand) {
        this.editor.commands[contentType]();
      }

      this.$emit('click', { contentType });
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
