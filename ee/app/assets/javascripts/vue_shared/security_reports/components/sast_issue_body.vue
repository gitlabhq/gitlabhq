<script>
/**
 * Renders SAST body text
 * [severity] ([confidence]): [name] in [link] : [line]
 */
import ReportLink from '~/reports/components/report_link.vue';
import ModalOpenName from '~/reports/components/modal_open_name.vue';

export default {
  name: 'SastIssueBody',

  components: {
    ReportLink,
    ModalOpenName,
  },

  props: {
    issue: {
      type: Object,
      required: true,
    },
    // failed || success
    status: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <div class="report-block-list-issue-description prepend-top-5 append-bottom-5">
    <div class="report-block-list-issue-description-text">
      <template v-if="issue.severity && issue.confidence">
        {{ issue.severity }} ({{ issue.confidence }}):
      </template>
      <template v-else-if="issue.severity">
        {{ issue.severity }}:
      </template>
      <template v-else-if="issue.confidence">
        ({{ issue.confidence }}):
      </template>
      <template v-else-if="issue.priority">{{ issue.priority }}:</template>

      <modal-open-name
        :issue="issue"
        :status="status"
      />
    </div>

    <report-link
      v-if="issue.path"
      :issue="issue"
    />
  </div>
</template>
