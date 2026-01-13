<script>
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { sidebarState } from '~/sidebar/sidebar_state';

export default {
  data() {
    return sidebarState;
  },
  computed: {
    reviewers() {
      return this.issuable?.reviewers?.nodes || [];
    },
  },
  methods: {
    getIdFromGraphQLId,
  },
};
</script>

<template>
  <div>
    <input
      v-for="reviewer in reviewers"
      :key="reviewer.id"
      type="hidden"
      name="merge_request[reviewer_ids][]"
      :value="getIdFromGraphQLId(reviewer.id)"
      :data-avatar-url="reviewer.avatarUrl"
      :data-name="reviewer.name"
      :data-username="reviewer.username"
      :data-can_merge="reviewer.mergeRequestInteraction.canMerge"
    />
  </div>
</template>
