<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlIcon } from '@gitlab/ui';

export default {
  components: {
    GlIcon,
  },
  props: {
    item: {
      type: Object,
      required: true,
    },
    currentId: {
      type: String,
      required: true,
    },
    currentProjectId: {
      type: String,
      required: true,
    },
  },
  computed: {
    isActive() {
      return (
        this.item.iid === parseInt(this.currentId, 10) &&
        this.currentProjectId === this.item.projectPathWithNamespace
      );
    },
    pathWithID() {
      return `${this.item.projectPathWithNamespace}!${this.item.iid}`;
    },
    mergeRequestHref() {
      const path = `/project/${this.item.projectPathWithNamespace}/merge_requests/${this.item.iid}`;

      return this.$router.resolve(path).href;
    },
  },
};
</script>

<template>
  <a :href="mergeRequestHref" class="btn-link gl-button gl-flex gl-items-center">
    <span class="ide-search-list-current-icon gl-mr-3 gl-flex">
      <gl-icon v-if="isActive" :size="16" name="mobile-issue-close" />
    </span>
    <span>
      <strong> {{ item.title }} </strong>
      <span class="ide-merge-request-project-path mt-1 gl-block"> {{ pathWithID }} </span>
    </span>
  </a>
</template>
