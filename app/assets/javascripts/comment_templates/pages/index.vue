<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlLoadingIcon, GlKeysetPagination } from '@gitlab/ui';
import { fetchPolicies } from '~/lib/graphql';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import CreateForm from '../components/form.vue';
import ListItem from '../components/list_item.vue';

const ENTRIES_PER_PAGE = 10;
const DEFAULT_PAGINATION = {
  first: ENTRIES_PER_PAGE,
  after: null,
  last: null,
  before: null,
};

export default {
  apollo: {
    savedReplies: {
      fetchPolicy: fetchPolicies.NETWORK_ONLY,
      query() {
        return this.fetchAllQuery;
      },
      update: (r) => r.object?.savedReplies?.nodes,
      variables() {
        return {
          path: this.path,
          ...this.pagination,
        };
      },
      result({ data }) {
        const pageInfo = data.object?.savedReplies?.pageInfo;

        this.count = data.object?.savedReplies?.count;

        if (pageInfo) {
          this.pageInfo = pageInfo;
        }
      },
    },
  },
  components: {
    GlLoadingIcon,
    GlKeysetPagination,
    CrudComponent,
    CreateForm,
    ListItem,
  },
  inject: {
    path: { default: '' },
    fetchAllQuery: { required: true },
  },
  data() {
    return {
      savedReplies: [],
      count: 0,
      pageInfo: {},
      pagination: DEFAULT_PAGINATION,
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.savedReplies.loading;
    },
  },
  methods: {
    refetchSavedReplies() {
      this.pagination = DEFAULT_PAGINATION;
      this.$apollo.queries.savedReplies.refetch();
      this.hideForm();
    },
    hideForm() {
      this.$refs.commentCrud.hideForm();
    },
    nextPage(item) {
      this.pagination = {
        first: ENTRIES_PER_PAGE,
        after: item,
        last: null,
        before: null,
      };
    },
    prevPage(item) {
      this.pagination = {
        first: null,
        after: null,
        last: ENTRIES_PER_PAGE,
        before: item,
      };
    },
  },
};
</script>

<template>
  <crud-component
    ref="commentCrud"
    :title="__('Comment templates')"
    icon="comment-lines"
    :count="count"
    :toggle-text="__('Add new')"
  >
    <template #form>
      <h4 class="gl-mt-0">{{ __('Add new comment template') }}</h4>
      <create-form @saved="refetchSavedReplies" @cancel="hideForm" />
    </template>

    <template #default>
      <gl-loading-icon v-if="isLoading" size="sm" class="gl-my-5" />
      <ul v-else-if="savedReplies && savedReplies.length" class="content-list">
        <list-item v-for="template in savedReplies" :key="template.id" :template="template" />
      </ul>

      <div v-else class="gl-text-subtle">
        {{ __('You have no comment templates yet.') }}
      </div>
    </template>

    <template v-if="!isLoading && pageInfo" #pagination>
      <gl-keyset-pagination
        v-if="pageInfo.hasPreviousPage || pageInfo.hasNextPage"
        v-bind="pageInfo"
        @prev="prevPage"
        @next="nextPage"
      />
    </template>
  </crud-component>
</template>
