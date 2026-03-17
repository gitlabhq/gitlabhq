<script>
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import getMergeRequestReviewersQuery from '~/sidebar/queries/get_merge_request_reviewers.query.graphql';

export default {
  inject: ['issuableIid', 'projectPath'],
  apollo: {
    issuable: {
      query: getMergeRequestReviewersQuery,
      variables() {
        return {
          iid: this.issuableIid,
          fullPath: this.projectPath,
        };
      },
      update(data) {
        return data.namespace?.issuable;
      },
    },
  },
  data() {
    return {
      issuable: null,
    };
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
