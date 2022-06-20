<script>
import { GlDropdown, GlDropdownItem, GlTooltipDirective as GlTooltip } from '@gitlab/ui';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
  },
  directives: {
    GlTooltip,
  },
  inject: ['tiptapEditor'],
  methods: {
    execute(contentType, attrs) {
      this.tiptapEditor.chain().focus().setNode(contentType, attrs).run();

      this.$emit('execute', { contentType });
    },
  },
};
</script>
<template>
  <gl-dropdown size="small" category="tertiary" icon="plus">
    <gl-dropdown-item @click="execute('diagram', { language: 'mermaid' })">
      {{ __('Mermaid diagram') }}
    </gl-dropdown-item>
    <gl-dropdown-item @click="execute('diagram', { language: 'plantuml' })">
      {{ __('PlantUML diagram') }}
    </gl-dropdown-item>
    <gl-dropdown-item @click="execute('horizontalRule')">
      {{ __('Horizontal rule') }}
    </gl-dropdown-item>
  </gl-dropdown>
</template>
