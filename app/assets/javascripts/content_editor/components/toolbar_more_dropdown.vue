<script>
import { GlTooltip, GlDisclosureDropdown } from '@gitlab/ui';
import { uniqueId } from 'lodash';

import { __ } from '~/locale';

export default {
  components: {
    GlDisclosureDropdown,
    GlTooltip,
  },
  inject: ['tiptapEditor', 'contentEditor'],
  data() {
    return {
      toggleId: uniqueId('dropdown-toggle-btn-'),
      items: [
        {
          text: __('Code block'),
          action: () => this.insert('codeBlock'),
        },
        {
          text: __('Details block'),
          action: () => this.insertList('details', 'detailsContent'),
        },
        {
          text: __('Bullet list'),
          action: () => this.insertList('bulletList', 'listItem'),
          wrapperClass: 'sm:!gl-hidden',
        },
        {
          text: __('Ordered list'),
          action: () => this.insertList('orderedList', 'listItem'),
          wrapperClass: 'sm:!gl-hidden',
        },
        {
          text: __('Task list'),
          action: () => this.insertList('taskList', 'taskItem'),
          wrapperClass: 'sm:!gl-hidden',
        },
        {
          text: __('Horizontal rule'),
          action: () => this.execute('setHorizontalRule', 'horizontalRule'),
        },
        {
          text: __('Mermaid diagram'),
          action: () => this.insert('diagram', { language: 'mermaid' }),
        },
        {
          text: __('PlantUML diagram'),
          action: () => this.insert('diagram', { language: 'plantuml' }),
        },
        ...(this.contentEditor.drawioEnabled
          ? [
              {
                text: __('Create or edit diagram'),
                action: () => this.execute('createOrEditDiagram', 'drawioDiagram'),
              },
            ]
          : []),
        {
          text: __('Table of contents'),
          action: () => this.execute('insertTableOfContents', 'tableOfContents'),
        },
      ],
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
  <div class="gl-inline-flex gl-align-middle">
    <gl-disclosure-dropdown
      :items="items"
      :toggle-id="toggleId"
      size="small"
      category="tertiary"
      icon="plus"
      :toggle-text="__('More options')"
      text-sr-only
      right
    />
    <gl-tooltip :target="toggleId" placement="top">{{ __('More options') }}</gl-tooltip>
  </div>
</template>
