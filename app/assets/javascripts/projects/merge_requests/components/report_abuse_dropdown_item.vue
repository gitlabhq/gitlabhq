<script>
import { GlDropdownItem } from '@gitlab/ui';
import { MountingPortal } from 'portal-vue';
import { s__ } from '~/locale';

import AbuseCategorySelector from '~/abuse_reports/components/abuse_category_selector.vue';

export default {
  name: 'ReportAbuseDropdownItem',
  components: {
    GlDropdownItem,
    MountingPortal,
    AbuseCategorySelector,
  },
  i18n: {
    reportAbuse: s__('ReportAbuse|Report abuse to administrator'),
  },
  data() {
    return {
      open: false,
    };
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
    <gl-dropdown-item @click="openDrawer">{{ $options.i18n.reportAbuse }}</gl-dropdown-item>

    <mounting-portal mount-to="#js-report-abuse-drawer" name="abuse-category-selector" append>
      <abuse-category-selector :show-drawer="open" @close-drawer="closeDrawer" />
    </mounting-portal>
  </span>
</template>
