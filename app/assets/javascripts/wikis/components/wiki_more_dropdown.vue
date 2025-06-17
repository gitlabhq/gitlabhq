<script>
import {
  GlIcon,
  GlDisclosureDropdown,
  GlDisclosureDropdownGroup,
  GlDisclosureDropdownItem,
  GlTooltipDirective,
} from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { isTemplate } from '../utils';
import CloneWikiModal from './clone_wiki_modal.vue';
import DeleteWikiModal from './delete_wiki_modal.vue';

export default {
  components: {
    GlIcon,
    GlDisclosureDropdown,
    GlDisclosureDropdownGroup,
    GlDisclosureDropdownItem,
    CloneWikiModal,
    DeleteWikiModal,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: {
    newUrl: { default: null },
    historyUrl: { default: null },
    templatesUrl: { default: null },
    pagePersisted: { default: null },
  },
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
    newItem() {
      return {
        text: this.isTemplate ? s__('Wiki|New template') : s__('Wiki|New page'),
        href: this.newUrl,
        extraAttrs: {
          'data-testid': 'page-new-button',
        },
      };
    },
    historyItem() {
      return {
        text: this.isTemplate ? s__('Wiki|Template history') : s__('Wiki|Page history'),
        href: this.historyUrl,
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
    templateItem() {
      return {
        text: __('Templates'),
        href: this.templatesUrl,
        extraAttrs: {
          class: this.templateLinkClass,
          'data-testid': 'page-templates-button',
        },
      };
    },
    showDropdownTooltip() {
      return !this.isDropdownVisible ? this.$options.i18n.wikiActions : '';
    },
    showPrintItem() {
      return !this.isTemplate && this.pagePersisted;
    },
  },
  methods: {
    printPage() {
      document.querySelectorAll('img').forEach((img) => img.setAttribute('loading', 'eager'));
      document.querySelectorAll('details').forEach((detail) => detail.setAttribute('open', ''));

      window.print();
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
    placement="bottom-end"
    no-caret
    data-testid="wiki-more-dropdown"
    class="print:gl-hidden"
    @shown="showDropdown"
    @hidden="hideDropdown"
  >
    <gl-disclosure-dropdown-item v-if="newUrl" :item="newItem">
      <template #list-item>
        <gl-icon name="plus" class="gl-mr-2" variant="subtle" />
        {{ newItem.text }}
      </template>
    </gl-disclosure-dropdown-item>

    <gl-disclosure-dropdown-item v-if="templatesUrl" :item="templateItem">
      <template #list-item>
        <gl-icon name="template" class="gl-mr-2" variant="subtle" />
        {{ templateItem.text }}
      </template>
    </gl-disclosure-dropdown-item>

    <clone-wiki-modal show-as-dropdown-item />

    <gl-disclosure-dropdown-group v-if="historyUrl || showPrintItem" bordered>
      <gl-disclosure-dropdown-item v-if="historyUrl" :item="historyItem">
        <template #list-item>
          <gl-icon name="history" class="gl-mr-2" variant="subtle" />
          {{ historyItem.text }}
        </template>
      </gl-disclosure-dropdown-item>
      <gl-disclosure-dropdown-item
        v-if="showPrintItem"
        :item="printItem"
        data-event-tracking="click_print_as_pdf_in_wiki_page"
      >
        <template #list-item>
          <gl-icon name="document" class="gl-mr-2" variant="subtle" />
          {{ printItem.text }}
        </template>
      </gl-disclosure-dropdown-item>
    </gl-disclosure-dropdown-group>

    <gl-disclosure-dropdown-group v-if="pagePersisted" bordered>
      <delete-wiki-modal show-as-dropdown-item />
    </gl-disclosure-dropdown-group>
  </gl-disclosure-dropdown>
</template>
