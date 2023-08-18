<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { fetchPolicies } from '~/lib/graphql';
import customEmojisQuery from '../queries/custom_emojis.query.graphql';
import List from '../components/list.vue';

export default {
  apollo: {
    customEmojis: {
      fetchPolicy: fetchPolicies.NETWORK_ONLY,
      query: customEmojisQuery,
      update: (r) => r.group?.customEmoji?.nodes,
      variables() {
        return {
          groupPath: this.groupPath,
          ...this.pagination,
        };
      },
      result({ data }) {
        const pageInfo = data.group?.customEmoji?.pageInfo;
        this.count = data.group?.customEmoji?.count;
        this.userPermissions = data.group?.userPermissions;

        if (pageInfo) {
          this.pageInfo = pageInfo;
        }
      },
    },
  },
  components: {
    List,
  },
  inject: {
    groupPath: {
      default: '',
    },
  },
  data() {
    return {
      customEmojis: [],
      count: 0,
      pageInfo: {},
      pagination: {},
      userPermissions: {},
    };
  },
  methods: {
    refetchCustomEmojis() {
      this.$apollo.queries.customEmojis.refetch();
    },
    changePage(pageInfo) {
      this.pagination = pageInfo;
    },
  },
};
</script>

<template>
  <list
    :count="count"
    :loading="$apollo.queries.customEmojis.loading"
    :page-info="pageInfo"
    :custom-emojis="customEmojis"
    :user-permissions="userPermissions"
    @input="changePage"
  />
</template>
