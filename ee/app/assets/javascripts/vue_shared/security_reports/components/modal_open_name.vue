<script>
import { mapActions } from 'vuex';

export default {
  props: {
    issue: {
      type: Object,
      required: true,
    },
  },
  methods: {
    ...mapActions(['openModal']),
    handleIssueClick() {
      this.openModal(this.issue);
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
