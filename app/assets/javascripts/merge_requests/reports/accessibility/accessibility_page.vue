<script>
import { InternalEvents } from '~/tracking';
import {
  ACCESSIBILITY_ROUTE,
  VIEW_MERGE_REQUEST_REPORT,
  TRACKING_LABEL_BY_ROUTE,
} from '~/merge_requests/reports/constants';
import AccessibilityProvider from './accessibility_provider.vue';
import AccessibilityContent from './accessibility_content.vue';

export default {
  name: 'AccessibilityPage',
  components: {
    AccessibilityProvider,
    AccessibilityContent,
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
      label: TRACKING_LABEL_BY_ROUTE[ACCESSIBILITY_ROUTE],
    });
  },
};
</script>

<template>
  <accessibility-provider :mr="mr">
    <accessibility-content />
  </accessibility-provider>
</template>
