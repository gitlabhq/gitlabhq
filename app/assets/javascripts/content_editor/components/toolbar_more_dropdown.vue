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
  data() {
    return {
      isActive: {},
    };
  },
  methods: {
    insert(contentType, ...args) {
      this.tiptapEditor
        .chain()
        .focus()
        .setNode(contentType, ...args)
        .run();

      this.$emit('execute', { contentType });
    },

    insertList(listType, listItemType) {
      if (!this.tiptapEditor.isActive(listType))
        this.tiptapEditor.chain().focus().toggleList(listType, listItemType).run();

      this.$emit('execute', { contentType: listType });
    },

    execute(command, contentType, ...args) {
      this.tiptapEditor
        .chain()
        .focus()
        [command](...args)
        .run();

      this.$emit('execute', { contentType });
    },
  },
};
</script>
<template>
  <gl-dropdown
    v-gl-tooltip
    size="small"
    category="tertiary"
    icon="plus"
    :text="__('More')"
    :title="__('More')"
    text-sr-only
    class="content-editor-dropdown"
    right
    lazy
  >
    <gl-dropdown-item @click="insert('comment')">
      {{ __('Comment') }}
    </gl-dropdown-item>
    <gl-dropdown-item @click="insert('codeBlock')">
      {{ __('Code block') }}
    </gl-dropdown-item>
    <gl-dropdown-item @click="insertList('details', 'detailsContent')">
      {{ __('Details block') }}
    </gl-dropdown-item>
    <gl-dropdown-item class="gl-sm-display-none!" @click="insertList('bulletList', 'listItem')">
      {{ __('Bullet list') }}
    </gl-dropdown-item>
    <gl-dropdown-item class="gl-sm-display-none!" @click="insertList('orderedList', 'listItem')">
      {{ __('Ordered list') }}
    </gl-dropdown-item>
    <gl-dropdown-item class="gl-sm-display-none!" @click="insertList('taskList', 'taskItem')">
      {{ __('Task list') }}
    </gl-dropdown-item>
    <gl-dropdown-item @click="execute('setHorizontalRule', 'horizontalRule')">
      {{ __('Horizontal rule') }}
    </gl-dropdown-item>
    <gl-dropdown-item @click="insert('diagram', { language: 'mermaid' })">
      {{ __('Mermaid diagram') }}
    </gl-dropdown-item>
    <gl-dropdown-item @click="insert('diagram', { language: 'plantuml' })">
      {{ __('PlantUML diagram') }}
    </gl-dropdown-item>
    <gl-dropdown-item @click="execute('insertTableOfContents', 'tableOfContents')">
      {{ __('Table of contents') }}
    </gl-dropdown-item>
  </gl-dropdown>
</template>
