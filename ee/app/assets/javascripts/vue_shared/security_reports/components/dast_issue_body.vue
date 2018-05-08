<script>
/**
 * Renders DAST body text
 * [priority]: [name]
 */

import ModalOpenName from './modal_open_name.vue';

export default {
  name: 'SastIssueBody',
  components: {
    ModalOpenName,
  },
  props: {
    issue: {
      type: Object,
      required: true,
    },

    issueIndex: {
      type: Number,
      required: true,
    },
  },
};
</script>
<template>
  <div class="report-block-list-issue-description prepend-top-5 append-bottom-5">
    <div class="report-block-list-issue-description-text append-right-5">
      <template v-if="issue.priority">{{ issue.priority }}:</template>

      <modal-open-name
        :issue="issue"
        class="js-modal-dast"
      />
    </div>
  </div>
</template>
