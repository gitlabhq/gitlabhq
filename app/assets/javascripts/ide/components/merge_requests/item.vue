<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlIcon, GlButton } from '@gitlab/ui';

export default {
  components: {
    GlIcon,
    GlButton,
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
  <gl-button variant="link" :href="mergeRequestHref">
    <span class="gl-inline-block gl-whitespace-normal">
      <gl-icon v-if="isActive" :size="16" name="mobile-issue-close" class="gl-mr-3" />
      <strong> {{ item.title }} </strong>
      <span class="ide-merge-request-project-path mt-1 gl-block"> {{ pathWithID }} </span>
    </span>
  </gl-button>
</template>
