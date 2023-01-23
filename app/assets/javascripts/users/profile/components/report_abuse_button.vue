<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import { BV_HIDE_TOOLTIP } from '~/lib/utils/constants';

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
  inject: ['reportedUserId', 'reportedFromUrl'],
  i18n: {
    reportAbuse: s__('ReportAbuse|Report abuse to administrator'),
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
    toggleDrawer(open) {
      this.open = open;
    },
    hideTooltips() {
      this.$root.$emit(BV_HIDE_TOOLTIP);
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
      @click="toggleDrawer(true)"
      @mouseout="hideTooltips"
    />
    <abuse-category-selector
      :reported-user-id="reportedUserId"
      :reported-from-url="reportedFromUrl"
      :show-drawer="open"
      @close-drawer="toggleDrawer(false)"
    />
  </span>
</template>
