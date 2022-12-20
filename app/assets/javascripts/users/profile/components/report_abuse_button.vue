<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';

import AbuseCategorySelector from '~/abuse_reports/components/abuse_category_selector.vue';

export default {
  name: 'ReportAbuseButton',
  components: {
    GlButton,
    AbuseCategorySelector,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['formSubmitPath', 'userId', 'reportedFromUrl'],
  i18n: {
    reportAbuse: __('Report abuse to administrator'),
  },
  data() {
    return {
      open: false,
    };
  },
  computed: {
    buttonTooltipText() {
      return this.$options.i18n.reportAbuse;
    },
  },
  methods: {
    openDrawer() {
      this.open = true;
    },
    closeDrawer() {
      this.open = false;
    },
  },
};
</script>
<template>
  <span>
    <gl-button
      v-gl-tooltip="buttonTooltipText"
      category="primary"
      :aria-label="buttonTooltipText"
      icon="error"
      @click="openDrawer"
    />
    <abuse-category-selector :show-drawer="open" @close-drawer="closeDrawer" />
  </span>
</template>
