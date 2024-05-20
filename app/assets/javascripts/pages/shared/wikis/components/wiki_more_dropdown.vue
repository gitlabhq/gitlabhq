<script>
import {
  GlDisclosureDropdown,
  GlDisclosureDropdownGroup,
  GlDisclosureDropdownItem,
  GlTooltipDirective,
} from '@gitlab/ui';
import { s__, __ } from '~/locale';
import printMarkdownDom from '~/lib/print_markdown_dom';
import { isTemplate } from '../utils';
import DeleteWikiModal from './delete_wiki_modal.vue';

export default {
  components: {
    GlDisclosureDropdown,
    GlDisclosureDropdownGroup,
    GlDisclosureDropdownItem,
    DeleteWikiModal,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['print', 'history', 'pagePersisted'],
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
    historyItem() {
      return {
        text: this.isTemplate ? s__('Wiki|Template history') : s__('Wiki|Page history'),
        href: this.history,
        extraAttrs: {
          'data-testid': 'page-history-button',
        },
      };
    },
    printItem() {
      return {
        text: __('Print as PDF'),
        action: this.printPage,
        extraAttrs: {
          'data-testid': 'page-print-button',
        },
      };
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
    icon="ellipsis_v"
    category="tertiary"
    placement="right"
    no-caret
    data-testid="wiki-more-dropdown"
    @shown="showDropdown"
    @hidden="hideDropdown"
  >
    <gl-disclosure-dropdown-item v-if="history" :item="historyItem" />
    <gl-disclosure-dropdown-item v-if="print && !isTemplate" :item="printItem" />
    <gl-disclosure-dropdown-group v-if="pagePersisted" bordered>
      <delete-wiki-modal show-as-dropdown-item />
    </gl-disclosure-dropdown-group>
  </gl-disclosure-dropdown>
</template>
