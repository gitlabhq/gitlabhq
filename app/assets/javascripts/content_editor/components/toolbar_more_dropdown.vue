<script>
import { GlTooltip, GlDisclosureDropdown, GlBadge } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { __ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import GlqlPopover from './glql_popover.vue';

export default {
  components: {
    GlDisclosureDropdown,
    GlTooltip,
    GlBadge,
    GlqlPopover,
  },
  inject: ['tiptapEditor', 'contentEditor'],
  data() {
    return {
      glqlPopoverVisible: true,
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
          text: __('Embedded view'),
          action: () => this.execute('insertGLQLView', 'glqlView'),
          badge: {
            text: __('New'),
            variant: 'info',
            size: 'small',
            target: '_blank',
            href: helpPagePath('user/glql/_index'),
          },
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
    <glql-popover v-model="glqlPopoverVisible" target="toolbar-more-dropdown" />
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
      @click="glqlPopoverVisible = false"
    >
      <template #list-item="{ item }">
        <span class="gl-flex gl-items-center gl-justify-between">
          {{ item.text }}
          <gl-badge v-if="item.badge" v-bind="item.badge" class="gl-ml-4" @click.stop>
            {{ item.badge.text }}
          </gl-badge>
        </span>
      </template>
    </gl-disclosure-dropdown>
    <gl-tooltip :target="toggleId" placement="top">{{ __('More options') }}</gl-tooltip>
  </div>
</template>
