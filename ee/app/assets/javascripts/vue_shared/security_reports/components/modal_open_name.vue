<script>
import { mapActions } from 'vuex';

export default {
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
  methods: {
    ...mapActions(['openModal']),
    handleIssueClick() {
      const { issue, status, openModal } = this;
      openModal({ issue, status });
    },
  },
};
</script>
<template>
  <button
    type="button"
    class="btn-link btn-blank text-left break-link vulnerability-name-button"
    @click="handleIssueClick()"
  >
    {{ issue.title }}
  </button>
</template>
