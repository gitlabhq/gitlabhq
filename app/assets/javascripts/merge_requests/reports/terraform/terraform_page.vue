<script>
import { InternalEvents } from '~/tracking';
import {
  TERRAFORM_ROUTE,
  VIEW_MERGE_REQUEST_REPORT,
  TRACKING_LABEL_BY_ROUTE,
} from '~/merge_requests/reports/constants';
import TerraformProvider from './terraform_provider.vue';
import TerraformContent from './terraform_content.vue';

export default {
  name: 'TerraformPage',
  components: {
    TerraformProvider,
    TerraformContent,
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
      label: TRACKING_LABEL_BY_ROUTE[TERRAFORM_ROUTE],
    });
  },
};
</script>

<template>
  <terraform-provider :mr="mr">
    <terraform-content />
  </terraform-provider>
</template>
