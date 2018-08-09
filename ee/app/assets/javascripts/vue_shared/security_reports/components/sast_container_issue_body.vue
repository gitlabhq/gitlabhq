<script>
/**
 * Renders SAST CONTAINER body text
 * [priority]: [name] in [link]:[line]
 */
import ReportLink from '~/reports/components/report_link.vue';
import ModalOpenName from '~/reports/components/modal_open_name.vue';

export default {
  name: 'SastContainerIssueBody',
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
      <template v-if="issue.severity">{{ issue.severity }}:</template>

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
