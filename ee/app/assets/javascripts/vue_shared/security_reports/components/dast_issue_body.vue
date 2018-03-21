<script>
  /**
   * Renders DAST body text
   * [priority]: [name]
   */
  export default {
    name: 'SastIssueBody',
    props: {
      issue: {
        type: Object,
        required: true,
      },

      issueIndex: {
        type: Number,
        required: true,
      },

      modalTargetId: {
        type: String,
        required: true,
      },
    },

    methods: {
      openDastModal() {
        this.$emit('openDastModal', this.issue, this.issueIndex);
      },
    },
  };
</script>
<template>
  <div class="report-block-list-issue-description prepend-top-5 append-bottom-5">
    <div class="report-block-list-issue-description-text append-right-5">
      <template v-if="issue.priority">{{ issue.priority }}:</template>

      <button
        type="button"
        @click="openDastModal()"
        data-toggle="modal"
        class="js-modal-dast btn-link btn-blank text-left break-link"
        :data-target="modalTargetId"
      >
        {{ issue.name }}
      </button>
    </div>
  </div>
</template>
