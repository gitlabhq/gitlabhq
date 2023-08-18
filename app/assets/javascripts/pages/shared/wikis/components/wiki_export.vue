<script>
import { GlDisclosureDropdown } from '@gitlab/ui';
import { __ } from '~/locale';
import printMarkdownDom from '~/lib/print_markdown_dom';

export default {
  components: {
    GlDisclosureDropdown,
  },
  inject: ['target', 'title', 'stylesheet'],
  computed: {
    dropdownItems() {
      return [
        {
          text: __('Print as PDF'),
          action: this.print,
        },
      ];
    },
  },
  methods: {
    print() {
      printMarkdownDom({
        target: document.querySelector(this.target),
        title: this.title,
        stylesheet: this.stylesheet,
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
  />
</template>
