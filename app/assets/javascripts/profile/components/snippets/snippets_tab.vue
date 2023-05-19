<script>
import { GlTab, GlKeysetPagination, GlEmptyState } from '@gitlab/ui';
import { s__ } from '~/locale';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import { SNIPPET_MAX_LIST_COUNT } from '~/profile/constants';
import getUserSnippets from '../graphql/get_user_snippets.query.graphql';
import SnippetRow from './snippet_row.vue';

export default {
  name: 'SnippetsTab',
  i18n: {
    title: s__('UserProfile|Snippets'),
    noSnippets: s__('UserProfiles|No snippets found.'),
  },
  components: {
    GlTab,
    GlKeysetPagination,
    GlEmptyState,
    SnippetRow,
  },
  inject: ['userId', 'snippetsEmptyState'],
  data() {
    return {
      userInfo: {},
      pageInfo: {},
      cursor: {
        first: SNIPPET_MAX_LIST_COUNT,
        last: null,
      },
    };
  },
  apollo: {
    userSnippets: {
      query: getUserSnippets,
      variables() {
        return {
          id: convertToGraphQLId(TYPENAME_USER, this.userId),
          ...this.cursor,
        };
      },
      update(data) {
        this.userInfo = {
          avatarUrl: data.user?.avatarUrl,
          name: data.user?.name,
          username: data.user?.username,
        };
        this.pageInfo = data?.user?.snippets?.pageInfo;
        return data?.user?.snippets?.nodes || [];
      },
      error() {
        return [];
      },
    },
  },
  computed: {
    hasSnippets() {
      return this.userSnippets?.length;
    },
  },
  methods: {
    isLastSnippet(index) {
      return index === this.userSnippets.length - 1;
    },
    nextPage() {
      this.cursor = {
        first: SNIPPET_MAX_LIST_COUNT,
        last: null,
        afterToken: this.pageInfo.endCursor,
      };
    },
    prevPage() {
      this.cursor = {
        first: null,
        last: SNIPPET_MAX_LIST_COUNT,
        beforeToken: this.pageInfo.startCursor,
      };
    },
  },
};
</script>

<template>
  <gl-tab :title="$options.i18n.title">
    <template v-if="hasSnippets">
      <snippet-row
        v-for="(snippet, index) in userSnippets"
        :key="snippet.id"
        :snippet="snippet"
        :user-info="userInfo"
        :class="{ 'gl-border-b': !isLastSnippet(index) }"
      />
      <div class="gl-display-flex gl-justify-content-center gl-mt-6">
        <gl-keyset-pagination
          v-if="pageInfo.hasPreviousPage || pageInfo.hasNextPage"
          v-bind="pageInfo"
          @prev="prevPage"
          @next="nextPage"
        />
      </div>
    </template>
    <template v-if="!hasSnippets">
      <gl-empty-state class="gl-mt-5" :svg-height="75" :svg-path="snippetsEmptyState">
        <template #title>
          <p class="gl-font-weight-bold gl-mt-n5">{{ $options.i18n.noSnippets }}</p>
        </template>
      </gl-empty-state>
    </template>
  </gl-tab>
</template>
