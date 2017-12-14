<script>
  import { spriteIcon } from '~/lib/utils/common_utils';

  export default {
    name: 'mrWidgetReportIssues',
    props: {
      issues: {
        type: Array,
        required: true,
      },
      // security || codequality || performance || docker
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
        return this.isStatusSuccess ? spriteIcon('plus') : spriteIcon('cut');
      },
      isStatusFailed() {
        return this.status === 'failed';
      },
      isStatusSuccess() {
        return this.status === 'success';
      },
      isStatusNeutral() {
        return this.status === 'neutral';
      },
      isTypeQuality() {
        return this.type === 'codequality';
      },
      isTypePerformance() {
        return this.type === 'performance';
      },
      isTypeSecurity() {
        return this.type === 'security';
      },
      isTypeDocker() {
        return this.type === 'docker';
      },
    },
    methods: {
      shouldRenderPriority(issue) {
        return (this.isTypeSecurity || this.isTypeDocker) && issue.priority;
      },
    },
  };
</script>
<template>
  <ul class="mr-widget-code-quality-list">
    <li
      :class="{
        failed: isStatusFailed,
        success: isStatusSuccess,
        neutral: isStatusNeutral
      }
      "v-for="issue in issues">

     <span
        class="mr-widget-code-quality-icon"
        v-html="icon">
      </span>

      <template v-if="isStatusSuccess && isTypeQuality">Fixed:</template>
      <template v-if="shouldRenderPriority(issue)">{{issue.priority}}:</template>

      <template v-if="isTypeDocker">
        <a
          v-if="issue.nameLink"
          :href="issue.nameLink"
          target="_blank"
          rel="noopener noreferrer nofollow">
          {{issue.name}}
        </a>
        <template v-else>
          {{issue.name}}
        </template>
      </template>
      <template v-else>
        {{issue.name}}<template v-if="issue.score">: <strong>{{issue.score}}</strong></template>
      </template>

      <template v-if="isTypePerformance && issue.delta != null">
        ({{issue.delta >= 0 ? '+' : ''}}{{issue.delta}})
      </template>

      <template v-if="issue.path">
        in

        <a
          v-if="issue.urlPath"
          :href="issue.urlPath"
          target="_blank"
          rel="noopener noreferrer nofollow">
          {{issue.path}}<template v-if="issue.line">:{{issue.line}}</template>
        </a>
        <template v-else>
          {{issue.path}}<template v-if="issue.line">:{{issue.line}}</template>
        </template>
      </template>

    </li>
  </ul>
</template>
