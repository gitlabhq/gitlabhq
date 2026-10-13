<script>
import { InternalEvents } from '~/tracking';
import {
  TEST_SUMMARY_ROUTE,
  VIEW_MERGE_REQUEST_REPORT,
  TRACKING_LABEL_BY_ROUTE,
} from '~/merge_requests/reports/constants';
import TestSummaryProvider from './test_summary_provider.vue';
import TestSummaryContent from './test_summary_content.vue';

export default {
  name: 'TestSummaryPage',
  components: {
    TestSummaryProvider,
    TestSummaryContent,
  },
  mixins: [InternalEvents.mixin()],
  props: {
    mr: {
      type: Object,
      required: true,
    },
  },
  mounted() {
    this.trackEvent(VIEW_MERGE_REQUEST_REPORT, {
      label: TRACKING_LABEL_BY_ROUTE[TEST_SUMMARY_ROUTE],
    });
  },
};
</script>

<template>
  <test-summary-provider :mr="mr">
    <test-summary-content />
  </test-summary-provider>
</template>
