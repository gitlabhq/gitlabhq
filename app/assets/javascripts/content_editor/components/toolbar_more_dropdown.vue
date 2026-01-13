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
      isDropdownOpen: false,
      toggleId: uniqueId('dropdown-toggle-btn-'),
      items: [
        {
          text: __('Alert'),
          action: () => this.execute('insertAlert', 'alert'),
        },
        {
          text: __('Code block'),
          action: () => this.insert('codeBlock'),
        },
        {
          text: __('Collapsible section'),
          action: () => this.insertList('details', 'detailsContent'),
        },
        {
          text: __('Bullet list'),
          action: () => this.insertList('bulletList', 'listItem'),
          wrapperClass: '@sm/panel:!gl-hidden',
        },
        {
          text: __('Ordered list'),
          action: () => this.insertList('orderedList', 'listItem'),
          wrapperClass: '@sm/panel:!gl-hidden',
        },
        {
          text: __('Task list'),
          action: () => this.insertList('taskList', 'taskItem'),
          wrapperClass: '@sm/panel:!gl-hidden',
        },
        {
          text: __('Horizontal rule'),
          action: () => this.execute('setHorizontalRule', 'horizontalRule'),
        },
        {
          text: __('Embedded view'),
          action: () => this.execute('insertGLQLView', 'glqlView'),
        },
        {
          text: __('Mermaid diagram'),
          action: () => this.execute('insertMermaid', 'diagram'),
        },
        {
          text: __('PlantUML diagram'),
          action: () => this.execute('insertPlantUML', 'diagram'),
        },
        ...(this.contentEditor.drawioEnabled
          ? [
              {
                text: __('Create or edit diagram'),
                action: () => this.execute('createOrEditDiagram', 'drawioDiagram'),
              },
            ]
          : []),
        ...(this.contentEditor.supportsTableOfContents
          ? [
              {
                text: __('Table of contents'),
                action: () => this.execute('insertTableOfContents', 'tableOfContents'),
              },
            ]
          : []),
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
      id="toolbar-more-dropdown"
      :items="items"
      :toggle-id="toggleId"
      size="small"
      category="tertiary"
      icon="plus"
      :toggle-text="__('More options')"
      text-sr-only
      right
      @shown="isDropdownOpen = true"
      @hidden="isDropdownOpen = false"
    >
      <template #list-item="{ item }">
        {{ item.text }}
      </template>
    </gl-disclosure-dropdown>
    <gl-tooltip v-if="!isDropdownOpen" :target="toggleId" placement="top">
      {{ __('More options') }}
    </gl-tooltip>
  </div>
</template>
