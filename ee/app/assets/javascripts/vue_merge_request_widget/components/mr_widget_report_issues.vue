<script>
  import { spriteIcon } from '~/lib/utils/common_utils';

  export default {
    name: 'mrWidgetReportIssues',
    props: {
      issues: {
        type: Array,
        required: true,
      },
      // security || codequality
      type: {
        type: String,
        required: true,
      },
      // failed || success
      status: {
        type: String,
        required: true,
      },
    },
    computed: {
      icon() {
        return this.isStatusFailed ? spriteIcon('cut') : spriteIcon('plus');
      },
      isStatusFailed() {
        return this.status === 'failed';
      },
      isStatusSuccess() {
        return this.status === 'success';
      },
      isTypeQuality() {
        return this.type === 'codequality';
      },
      isTypeSecurity() {
        return this.type === 'security';
      },
    },
  };
</script>
<template>
  <ul class="mr-widget-code-quality-list">
    <li
      :class="{
        failed: isStatusFailed,
        success: isStatusSuccess
      }
      "v-for="issue in issues">

     <span
        class="mr-widget-code-quality-icon"
        v-html="icon">
      </span>

      <template v-if="isStatusSuccess && isTypeQuality">Fixed:</template>
      <template v-if="isTypeSecurity && issue.priority">{{issue.priority}}:</template>

      {{issue.name}}

      <template v-if="issue.path">
        in

        <a
          :href="issue.urlPath"
          target="_blank"
          rel="noopener noreferrer nofollow">
          {{issue.path}}<template v-if="issue.line">:{{issue.line}}</template>
        </a>
      </template>

    </li>
  </ul>
</template>
