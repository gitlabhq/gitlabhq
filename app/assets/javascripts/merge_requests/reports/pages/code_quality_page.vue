<script>
import CodeQualityProvider from '~/merge_requests/reports/components/code_quality_provider.vue';
import CodeQualityContent from '~/merge_requests/reports/components/code_quality_content.vue';

export default {
  name: 'CodeQualityPage',
  components: {
    CodeQualityProvider,
    CodeQualityContent,
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
    <code-quality-content />
  </code-quality-provider>
</template>
