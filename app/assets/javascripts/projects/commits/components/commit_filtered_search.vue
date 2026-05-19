<script>
import { GlFilteredSearchToken } from '@gitlab/ui';
import {
  TOKEN_TYPE_AUTHOR,
  TOKEN_TITLE_AUTHOR,
  TOKEN_TYPE_MESSAGE,
  TOKEN_TITLE_MESSAGE,
  OPERATORS_IS,
  TOKEN_TYPE_COMMITTED_AFTER,
  TOKEN_TYPE_COMMITTED_BEFORE,
  TOKEN_TITLE_COMMITTED_AFTER,
  TOKEN_TITLE_COMMITTED_BEFORE,
} from '~/vue_shared/components/filtered_search_bar/constants';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import UserToken from '~/vue_shared/components/filtered_search_bar/tokens/user_token.vue';
import DateToken from '~/vue_shared/components/filtered_search_bar/tokens/date_token.vue';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_USER } from '~/graphql_shared/constants';

export default {
  name: 'CommitFilteredSearch',
  components: {
    FilteredSearchBar,
  },
  inject: ['projectFullPath'],
  props: {
    initialFilterTokens: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  emits: ['filter'],
  data() {
    return {
      filterTokens: [...this.initialFilterTokens],
    };
  },
  computed: {
    tokens() {
      return [
        {
          type: TOKEN_TYPE_AUTHOR,
          title: TOKEN_TITLE_AUTHOR,
          icon: 'pencil',
          token: UserToken,
          dataType: 'user',
          valueField: 'name',
          defaultUsers: [],
          operators: OPERATORS_IS,
          fullPath: this.projectFullPath,
          isProject: true,
          recentSuggestionsStorageKey: `${this.projectFullPath}-commits-recent-tokens-author`,
          preloadedUsers: this.preloadedUsers,
          unique: true,
        },
        {
          type: TOKEN_TYPE_MESSAGE,
          title: TOKEN_TITLE_MESSAGE,
          icon: 'comment',
          token: GlFilteredSearchToken,
          operators: OPERATORS_IS,
          unique: true,
        },
        {
          type: TOKEN_TYPE_COMMITTED_AFTER,
          title: TOKEN_TITLE_COMMITTED_AFTER,
          icon: 'calendar',
          token: DateToken,
          operators: OPERATORS_IS,
          unique: true,
        },
        {
          type: TOKEN_TYPE_COMMITTED_BEFORE,
          title: TOKEN_TITLE_COMMITTED_BEFORE,
          icon: 'calendar',
          token: DateToken,
          operators: OPERATORS_IS,
          unique: true,
        },
      ];
    },
    preloadedUsers() {
      if (!gon.current_user_id) {
        return [];
      }
      return [
        {
          id: convertToGraphQLId(TYPENAME_USER, gon.current_user_id),
          name: gon.current_user_fullname,
          username: gon.current_username,
          avatar_url: gon.current_user_avatar_url,
        },
      ];
    },
  },
  watch: {
    initialFilterTokens: {
      handler(newTokens) {
        this.filterTokens = [...newTokens];
      },
      deep: true,
    },
  },
};
</script>

<template>
  <filtered-search-bar
    :namespace="projectFullPath"
    :tokens="tokens"
    :initial-filter-value="filterTokens"
    :search-input-placeholder="__('Search or filter results...')"
    recent-searches-storage-key="commits"
    show-friendly-text
    sync-filter-and-sort
    terms-as-tokens
    @onFilter="$emit('filter', $event)"
  />
</template>
