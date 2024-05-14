<script>
import { GlDisclosureDropdown, GlTooltipDirective } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import printMarkdownDom from '~/lib/print_markdown_dom';
import { isTemplate } from '../utils';

export default {
  components: {
    GlDisclosureDropdown,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['print', 'history'],
  i18n: {
    wikiActions: s__('Wiki|Wiki actions'),
  },
  data() {
    return {
      isDropdownVisible: false,
    };
  },
  computed: {
    isTemplate,
    dropdownItems() {
      const items = [];

      if (this.history) {
        items.push({
          text: this.isTemplate ? s__('Wiki|Template history') : s__('Wiki|Page history'),
          href: this.history,
          extraAttrs: {
            'data-testid': 'page-history-button',
          },
        });
      }

      if (this.print && !this.isTemplate) {
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
    showDropdownTooltip() {
      return !this.isDropdownVisible ? this.$options.i18n.wikiActions : '';
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
    showDropdown() {
      this.isDropdownVisible = true;
    },
    hideDropdown() {
      this.isDropdownVisible = false;
    },
  },
};
</script>
<template>
  <gl-disclosure-dropdown
    v-gl-tooltip="showDropdownTooltip"
    :items="dropdownItems"
    icon="ellipsis_v"
    category="tertiary"
    placement="right"
    no-caret
    data-testid="wiki-more-dropdown"
    @shown="showDropdown"
    @hidden="hideDropdown"
  />
</template>
