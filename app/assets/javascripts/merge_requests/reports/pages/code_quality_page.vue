<script>
import CodeQualityProvider from '~/merge_requests/reports/components/code_quality_provider.vue';

export default {
  name: 'CodeQualityPage',
  components: {
    CodeQualityProvider,
  },
  props: {
    mr: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <code-quality-provider :mr="mr">
    <div>{{ s__('MrReports|Code quality') }}</div>
  </code-quality-provider>
</template>
