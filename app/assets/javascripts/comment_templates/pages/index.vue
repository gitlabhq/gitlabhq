<script>
import { fetchPolicies } from '~/lib/graphql';
import CreateForm from '../components/form.vue';
import savedRepliesQuery from '../queries/saved_replies.query.graphql';
import List from '../components/list.vue';

export default {
  apollo: {
    savedReplies: {
      fetchPolicy: fetchPolicies.NETWORK_ONLY,
      query: savedRepliesQuery,
      update: (r) => r.currentUser?.savedReplies?.nodes,
      variables() {
        return {
          ...this.pagination,
        };
      },
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
    CreateForm,
    List,
  },
  data() {
    return {
      savedReplies: [],
      count: 0,
      pageInfo: {},
      pagination: {},
    };
  },
  methods: {
    refetchSavedReplies() {
      this.pagination = {};
      this.$apollo.queries.savedReplies.refetch();
    },
    changePage(pageInfo) {
      this.pagination = pageInfo;
    },
  },
};
</script>

<template>
  <div>
    <h5 class="gl-mt-0 gl-font-lg">
      {{ __('Add new comment template') }}
    </h5>
    <create-form @saved="refetchSavedReplies" />
    <list
      :loading="$apollo.queries.savedReplies.loading"
      :saved-replies="savedReplies"
      :page-info="pageInfo"
      :count="count"
      @input="changePage"
    />
  </div>
</template>
