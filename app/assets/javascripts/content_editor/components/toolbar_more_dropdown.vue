<script>
import { GlTooltip, GlDisclosureDropdown, GlBadge } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { helpPagePath } from '~/helpers/help_page_helper';
import { __ } from '~/locale';

export default {
  components: {
    GlDisclosureDropdown,
    GlTooltip,
    GlBadge,
  },
  inject: ['tiptapEditor', 'contentEditor'],
  data() {
    return {
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
          text: __('GitLab Query Language (GLQL) view'),
          action: () => this.execute('insertGLQLView', 'glqlView'),
          badge: {
            text: __('Beta'),
            variant: 'info',
            size: 'small',
            target: '_blank',
            href: helpPagePath('user/glql/_index'),
          },
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
