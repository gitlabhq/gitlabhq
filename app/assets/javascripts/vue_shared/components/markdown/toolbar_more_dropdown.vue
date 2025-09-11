<script>
import { GlTooltip, GlDisclosureDropdown, GlBadge } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import Tracking from '~/tracking';
import { __ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import { updateText } from '~/lib/utils/text_markdown';
import { DEFAULT_GLQL_VIEW_CONTENT } from '~/content_editor/extensions/code_block_highlight';
import {
  DEFAULT_MERMAID_CONTENT,
  DEFAULT_PLANTUML_CONTENT,
} from '~/content_editor/extensions/diagram';
import { TOOLBAR_CONTROL_TRACKING_ACTION, MARKDOWN_EDITOR_TRACKING_LABEL } from './tracking';

export default {
  components: {
    GlDisclosureDropdown,
    GlTooltip,
    GlBadge,
  },
  /* eslint-disable @gitlab/require-i18n-strings */
  data() {
    return {
      toggleId: uniqueId('dropdown-toggle-btn-'),
      items: [
        {
          text: __('Alert'),
          action: () => this.insertMarkdown('> [!NOTE]\n> {text}', 'alert'),
        },
        {
          text: __('Code block'),
          action: () => this.insertMarkdown('```\n{text}\n```', 'codeBlock'),
        },
        {
          text: __('Collapsible section'),
          action: () =>
            this.insertMarkdown(
              '<details>\n<summary>Click to expand</summary>\n\n{text}\n\n</details>',
              'details',
            ),
        },
        {
          text: __('Bullet list'),
          action: () => this.insertMarkdown('- {text}', 'bulletList'),
          wrapperClass: '@sm/panel:!gl-hidden',
        },
        {
          text: __('Ordered list'),
          action: () => this.insertMarkdown('1. {text}', 'orderedList'),
          wrapperClass: '@sm/panel:!gl-hidden',
        },
        {
          text: __('Task list'),
          action: () => this.insertMarkdown('- [ ] {text}', 'taskList'),
          wrapperClass: '@sm/panel:!gl-hidden',
        },
        {
          text: __('Horizontal rule'),
          action: () => this.insertMarkdown('\n---\n', 'horizontalRule'),
        },
        {
          text: __('Embedded view'),
          action: () =>
            this.insertMarkdown(`\`\`\`glql\n${DEFAULT_GLQL_VIEW_CONTENT}\n\`\`\``, 'glqlView'),
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
          action: () =>
            this.insertMarkdown(`\`\`\`mermaid\n${DEFAULT_MERMAID_CONTENT}\n\`\`\``, 'diagram'),
        },
        {
          text: __('PlantUML diagram'),
          action: () =>
            this.insertMarkdown(`\`\`\`plantuml\n${DEFAULT_PLANTUML_CONTENT}\n\`\`\``, 'diagram'),
        },
        {
          text: __('Table of contents'),
          action: () => this.insertMarkdown('[[_TOC_]]', 'tableOfContents'),
        },
      ],
    };
  },
  methods: {
    getCurrentTextArea() {
      return this.$el.closest('.md-area')?.querySelector('textarea');
    },
    insertMarkdown(markdownText, trackingProperty) {
      const textArea = this.getCurrentTextArea();
      if (!textArea) return;

      updateText({
        textArea,
        tag: markdownText,
        cursorOffset: 0,
        wrap: false,
      });

      Tracking.event(undefined, TOOLBAR_CONTROL_TRACKING_ACTION, {
        label: MARKDOWN_EDITOR_TRACKING_LABEL,
        property: trackingProperty,
      });
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
