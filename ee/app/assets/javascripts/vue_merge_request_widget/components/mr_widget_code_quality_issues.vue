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
      plusIcon() {
        return spriteIcon('plus');
      },
      minusIcon() {
        return spriteIcon('cut');
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
        v-if="isTypeFailed"
        v-html="minusIcon">
      </span>
      <span
        class="mr-widget-code-quality-icon"
        v-else-if="isTypeSuccess"
        v-html="plusIcon">
      </span>
      <span
        class="mr-widget-code-quality-title"
        v-if="isTypeSuccess">
        Fixed:
      </span>
      <span class="mr-widget-code-quality-title">
        {{issue.check_name}}
      </span>
      <template v-if="issue.location.path">in</template>
      <a
        :href="issue.location.urlPath"
        target="_blank"
        rel="noopener noreferrer nofollow">
        {{issue.location.path}}
      </a>
  </li>
  </ul>
</template>
