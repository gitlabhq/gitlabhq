<script>
import { GlFilteredSearchToken } from '@gitlab/ui';
import {
  TOKEN_TYPE_AUTHOR,
  TOKEN_TITLE_AUTHOR,
  TOKEN_TYPE_MESSAGE,
  TOKEN_TITLE_MESSAGE,
  OPERATORS_IS_NOT_OR,
  OPERATORS_IS,
} from '~/vue_shared/components/filtered_search_bar/constants';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import UserToken from '~/vue_shared/components/filtered_search_bar/tokens/user_token.vue';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_USER } from '~/graphql_shared/constants';

export default {
  name: 'CommitFilteredSearch',
  components: {
    FilteredSearchBar,
  },
  inject: ['projectFullPath'],
  emits: ['filter'],
  data() {
    return {
      filterTokens: [],
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
          defaultUsers: [],
          operators: OPERATORS_IS_NOT_OR,
          fullPath: this.projectFullPath,
          isProject: true,
          multiSelect: true,
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
    terms-as-tokens
    @onFilter="$emit('filter', $event)"
  />
</template>
