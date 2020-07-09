<script>
import { mapActions } from 'vuex';

export default {
  name: 'TestIssueBody',
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
    isNew: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  methods: {
    ...mapActions(['openModal']),
  },
};
</script>
<template>
  <div class="report-block-list-issue-description gl-mt-2 gl-mb-2">
    <div class="report-block-list-issue-description-text" data-testid="test-issue-body-description">
      <button
        type="button"
        class="btn-link btn-blank text-left break-link vulnerability-name-button"
        @click="openModal({ issue })"
      >
        <div v-if="isNew" class="badge badge-danger gl-mr-2">{{ s__('New') }}</div>
        {{ issue.name }}
      </button>
    </div>
  </div>
</template>
