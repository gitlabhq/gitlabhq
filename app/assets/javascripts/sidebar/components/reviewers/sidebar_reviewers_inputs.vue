<script>
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { state } from './sidebar_reviewers.vue';

export default {
  data() {
    return state;
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
