<script>
import { GlTooltip, GlDisclosureDropdown } from '@gitlab/ui';
import { uniqueId } from 'lodash-es';
import { __ } from '~/locale';

export default {
  name: 'ToolbarMoreDropdown',
  components: {
    GlDisclosureDropdown,
    GlTooltip,
  },
  inject: ['tiptapEditor', 'contentEditor'],
  emits: ['execute'],
  data() {
    return {
      isDropdownOpen: false,
      toggleId: uniqueId('dropdown-toggle-btn-'),
      items: [
        {
          text: __('Alert'),
          icon: 'warning',
          action: () => this.execute('insertAlert', 'alert'),
        },
        {
          text: __('Code block'),
          icon: 'code',
          action: () => this.insert('codeBlock'),
        },
        {
          text: __('Collapsible section'),
          icon: 'details-block',
          action: () => this.insertList('details', 'detailsContent'),
        },
        {
          text: __('Bullet list'),
          icon: 'list-bulleted',
          action: () => this.insertList('bulletList', 'listItem'),
          wrapperClass: '@sm/panel:!gl-hidden',
        },
        {
          text: __('Ordered list'),
          icon: 'list-numbered',
          action: () => this.insertList('orderedList', 'listItem'),
          wrapperClass: '@sm/panel:!gl-hidden',
        },
        {
          text: __('Task list'),
          icon: 'list-task',
          action: () => this.insertList('taskList', 'taskItem'),
          wrapperClass: '@sm/panel:!gl-hidden',
        },
        {
          text: __('Horizontal rule'),
          icon: 'dash',
          action: () => this.execute('setHorizontalRule', 'horizontalRule'),
        },
        {
          text: __('Embedded view'),
          icon: 'kind',
          action: () => this.execute('insertGLQLView', 'glqlView'),
        },
        {
          text: __('Mermaid diagram'),
          icon: 'diagram',
          action: () => this.execute('insertMermaid', 'diagram'),
        },
        {
          text: __('PlantUML diagram'),
          icon: 'diagram',
          action: () => this.execute('insertPlantUML', 'diagram'),
        },
        ...(this.contentEditor.drawioEnabled
          ? [
              {
                text: __('Create or edit diagram'),
                icon: 'pencil-square',
                action: () => this.execute('createOrEditDiagram', 'drawioDiagram'),
              },
            ]
          : []),
        ...(this.contentEditor.supportsTableOfContents
          ? [
              {
                text: __('Table of contents'),
                icon: 'title',
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
    />
    <gl-tooltip v-if="!isDropdownOpen" :target="toggleId" placement="top">
      {{ __('More options') }}
    </gl-tooltip>
  </div>
</template>
