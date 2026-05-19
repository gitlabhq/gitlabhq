<script>
import { InternalEvents } from '~/tracking';
import {
  CODE_QUALITY_ROUTE,
  VIEW_MERGE_REQUEST_REPORT,
  TRACKING_LABEL_BY_ROUTE,
} from '~/merge_requests/reports/constants';
import CodeQualityProvider from './code_quality_provider.vue';
import CodeQualityContent from './code_quality_content.vue';

export default {
  name: 'CodeQualityPage',
  components: {
    CodeQualityProvider,
    CodeQualityContent,
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
      label: TRACKING_LABEL_BY_ROUTE[CODE_QUALITY_ROUTE],
    });
  },
};
</script>

<template>
  <code-quality-provider :mr="mr">
    <code-quality-content />
  </code-quality-provider>
</template>
