<script>
import { GlKeysetPagination, GlLoadingIcon, GlSprintf } from '@gitlab/ui';
import savedRepliesQuery from '../queries/saved_replies.query.graphql';
import ListItem from './list_item.vue';

export default {
  apollo: {
    savedReplies: {
      query: savedRepliesQuery,
      update: (r) => r.currentUser?.savedReplies?.nodes,
      result({ data }) {
        const pageInfo = data.currentUser?.savedReplies?.pageInfo;

        this.count = data.currentUser?.savedReplies?.count;

        if (pageInfo) {
          this.pageInfo = pageInfo;
        }
      },
    },
  },
  components: {
    GlLoadingIcon,
    GlKeysetPagination,
    GlSprintf,
    ListItem,
  },
  data() {
    return {
      savedReplies: [],
      count: 0,
      pageInfo: {},
    };
  },
};
</script>

<template>
  <div>
    <gl-loading-icon v-if="$apollo.queries.savedReplies.loading" size="lg" />
    <template v-else>
      <h5 class="gl-font-lg" data-testid="title">
        <gl-sprintf :message="__('My saved replies (%{count})')">
          <template #count>{{ count }}</template>
        </gl-sprintf>
      </h5>
      <ul class="gl-list-style-none gl-p-0 gl-m-0">
        <list-item v-for="reply in savedReplies" :key="reply.id" :reply="reply" />
      </ul>
      <gl-keyset-pagination
        v-if="pageInfo.hasPreviousPage || pageInfo.hasNextPage"
        v-bind="pageInfo"
        class="gl-mt-4"
      />
    </template>
  </div>
</template>
