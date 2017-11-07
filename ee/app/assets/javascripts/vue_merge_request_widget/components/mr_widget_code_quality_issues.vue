<script>
  import { spriteIcon } from '~/lib/utils/common_utils';

  export default {
    name: 'MRWidgetCodeQualityIssues',
    props: {
      issues: {
        type: Array,
        required: true,
      },
      type: {
        type: String,
        required: true,
      },
    },
    computed: {
      icon() {
        return this.isTypeFailed ? spriteIcon('cut') : spriteIcon('plus');
      },
      isTypeFailed() {
        return this.type === 'failed';
      },
      isTypeSuccess() {
        return this.type === 'success';
      },
    },
  };
</script>
<template>
  <ul class="mr-widget-code-quality-list">
    <li
      :class="{
        failed: isTypeFailed,
        success: isTypeSuccess,
      }
      "v-for="issue in issues">
      <span
        class="mr-widget-code-quality-icon"
        v-html="icon">
      </span>
      <template v-if="isTypeSuccess">Fixed:</template>
      {{issue.check_name}}
      <template v-if="issue.location.path">in</template>
      <a
        :href="issue.location.urlPath"
        target="_blank"
        rel="noopener noreferrer nofollow">
        {{issue.location.path}}<template v-if="issue.location.lines && issue.location.lines.begin">:{{issue.location.lines.begin}}</template>
      </a>
  </li>
  </ul>
</template>
