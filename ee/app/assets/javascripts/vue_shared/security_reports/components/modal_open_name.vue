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
    @click="handleIssueClick()"
    class="btn-link btn-blank text-left break-link vulnerability-name-button"
  >
    {{ issue.title }}
  </button>
</template>
