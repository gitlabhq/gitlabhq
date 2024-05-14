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
  inject: ['reportedUserId', 'reportedFromUrl'],
  i18n: {
    reportAbuse: s__('ReportAbuse|Report abuse'),
  },
  data() {
    return {
      open: false,
    };
  },
  methods: {
    toggleDrawer(open) {
      this.open = open;
    },
  },
};
</script>
<template>
  <span>
    <gl-dropdown-item @click="toggleDrawer(true)">{{ $options.i18n.reportAbuse }}</gl-dropdown-item>

    <mounting-portal mount-to="#js-report-abuse-drawer" name="abuse-category-selector" append>
      <abuse-category-selector
        :reported-user-id="reportedUserId"
        :reported-from-url="reportedFromUrl"
        :show-drawer="open"
        @close-drawer="toggleDrawer(false)"
      />
    </mounting-portal>
  </span>
</template>
