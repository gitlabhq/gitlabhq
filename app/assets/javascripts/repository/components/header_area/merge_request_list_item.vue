<script>
import { GlBadge, GlIcon } from '@gitlab/ui';
import { getTimeago } from '~/lib/utils/datetime/timeago_utility';

export default {
  name: 'MergeRequestListItem',
  components: {
    GlBadge,
    GlIcon,
  },
  props: {
    mergeRequest: {
      type: Object,
      required: true,
    },
  },
  computed: {
    formattedTime() {
      return getTimeago().format(this.mergeRequest.createdAt);
    },
    mrMetaInfo() {
      return `${this.mergeRequest.project.fullPath} !${this.mergeRequest.iid}`;
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-flex-col gl-gap-1 gl-p-2">
    <div class="gl-flex gl-items-center gl-justify-between">
      <div class="gl-inline-flex gl-items-center gl-gap-2">
        <gl-badge class="gl-mr-2" variant="success">
          <gl-icon name="merge-request" />
          {{ s__('OpenMrBadge|Open') }}
        </gl-badge>
        <span class="gl-text-subtle">
          {{ s__('OpenMrBadge|Opened') }} <time v-text="formattedTime"></time
        ></span>
      </div>
    </div>
    <h5 class="my-2">{{ mergeRequest.title }}</h5>
    <div class="gl-flex gl-flex-col gl-gap-1 gl-text-subtle" data-testid="project-info">
      <div class="gl-flex gl-gap-1"><gl-icon name="project" />{{ mrMetaInfo }}</div>
      <div
        v-for="assignee in mergeRequest.assignees.nodes"
        :key="assignee.id"
        class="gl-flex gl-gap-1"
        data-testid="assignee-info"
      >
        <gl-icon name="user" />{{ assignee.name }}
      </div>
      <div class="gl-flex gl-gap-1" data-testid="source-branch-info">
        <gl-icon name="branch" />{{ mergeRequest.sourceBranch }}
      </div>
    </div>
  </div>
</template>
