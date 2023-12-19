<script>
import { GlDisclosureDropdown } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import printMarkdownDom from '~/lib/print_markdown_dom';

export default {
  components: {
    GlDisclosureDropdown,
  },
  inject: ['print', 'history'],
  computed: {
    dropdownItems() {
      const items = [];

      if (this.history) {
        items.push({
          text: s__('Wiki|Page history'),
          href: this.history,
          extraAttrs: {
            'data-testid': 'page-history-button',
          },
        });
      }

      if (this.print) {
        items.push({
          text: __('Print as PDF'),
          action: this.printPage,
          extraAttrs: {
            'data-testid': 'page-print-button',
          },
        });
      }

      return items;
    },
  },
  methods: {
    printPage() {
      printMarkdownDom({
        target: document.querySelector(this.print.target),
        title: this.print.title,
        stylesheet: this.print.stylesheet,
      });
    },
  },
};
</script>
<template>
  <gl-disclosure-dropdown
    :items="dropdownItems"
    icon="ellipsis_v"
    category="tertiary"
    placement="right"
    no-caret
    data-testid="wiki-more-dropdown"
  />
</template>
