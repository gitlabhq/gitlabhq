<script>
/**
 * Renders SAST body text
 * [priority]: [name] in [link] : [line]
 */
import ReportLink from './report_link.vue';

export default {
  name: 'SastIssueBody',

  components: {
    ReportLink,
  },

  props: {
    issue: {
      type: Object,
      required: true,
    },
  },
};
</script>
<template>
  <div class="report-block-list-issue-description prepend-top-5 append-bottom-5">
    <div class="report-block-list-issue-description-text append-right-5">
      <template v-if="issue.priority">{{ issue.priority }}:</template>

      {{ issue.name }}
    </div>

    <report-link
      v-if="issue.path"
      :issue="issue"
    />
  </div>
</template>
