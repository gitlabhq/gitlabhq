<script>
import { GlTab, GlKeysetPagination, GlEmptyState } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import { SNIPPET_MAX_LIST_COUNT } from '~/profile/constants';
import { isCurrentUser } from '~/lib/utils/common_utils';
import { helpPagePath } from '~/helpers/help_page_helper';
import getUserSnippets from '../graphql/get_user_snippets.query.graphql';
import SnippetRow from './snippet_row.vue';

export default {
  name: 'SnippetsTab',
  i18n: {
    title: s__('UserProfile|Snippets'),
    currentUserEmptyStateTitle: s__('UserProfile|Get started with snippets'),
    visitorEmptyStateTitle: s__("UserProfile|This user doesn't have any snippets"),
    emptyStateDescription: s__('UserProfile|Store, share, and embed bits of code and text.'),
    newSnippet: __('New snippet'),
    learnMore: __('Learn more'),
  },
  components: {
    GlTab,
    GlKeysetPagination,
    GlEmptyState,
    SnippetRow,
  },
  inject: ['userId', 'snippetsEmptyState', 'newSnippetPath'],
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
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
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
    emptyStateTitle() {
      return isCurrentUser(this.userId)
        ? this.$options.i18n.currentUserEmptyStateTitle
        : this.$options.i18n.visitorEmptyStateTitle;
    },
    emptyStateDescription() {
      return isCurrentUser(this.userId) ? this.$options.i18n.emptyStateDescription : null;
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
    helpPagePath,
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
      <div class="gl-mt-6 gl-flex gl-justify-center">
        <gl-keyset-pagination
          v-if="pageInfo.hasPreviousPage || pageInfo.hasNextPage"
          v-bind="pageInfo"
          @prev="prevPage"
          @next="nextPage"
        />
      </div>
    </template>
    <template v-if="!hasSnippets">
      <gl-empty-state
        class="gl-mt-5"
        :svg-path="snippetsEmptyState"
        :svg-height="144"
        :title="emptyStateTitle"
        :description="emptyStateDescription"
        :primary-button-link="newSnippetPath"
        :primary-button-text="$options.i18n.newSnippet"
        :secondary-button-text="$options.i18n.learnMore"
        :secondary-button-link="helpPagePath('user/snippets')"
      />
    </template>
  </gl-tab>
</template>
