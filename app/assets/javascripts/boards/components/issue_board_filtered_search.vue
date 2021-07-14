<script>
import BoardFilteredSearch from '~/boards/components/board_filtered_search.vue';
import issueBoardFilters from '~/boards/issue_board_filters';
import { TYPE_USER } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { __ } from '~/locale';
import AuthorToken from '~/vue_shared/components/filtered_search_bar/tokens/author_token.vue';
import LabelToken from '~/vue_shared/components/filtered_search_bar/tokens/label_token.vue';

export default {
  i18n: {
    search: __('Search'),
    label: __('Label'),
    author: __('Author'),
    assignee: __('Assignee'),
    is: __('is'),
    isNot: __('is not'),
  },
  components: { BoardFilteredSearch },
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    boardType: {
      type: String,
      required: true,
    },
  },
  computed: {
    tokens() {
      const { label, is, isNot, author, assignee } = this.$options.i18n;
      const { fetchAuthors, fetchLabels } = issueBoardFilters(
        this.$apollo,
        this.fullPath,
        this.boardType,
      );

      return [
        {
          icon: 'labels',
          title: label,
          type: 'label_name',
          operators: [
            { value: '=', description: is },
            { value: '!=', description: isNot },
          ],
          token: LabelToken,
          unique: false,
          symbol: '~',
          fetchLabels,
        },
        {
          icon: 'pencil',
          title: author,
          type: 'author_username',
          operators: [
            { value: '=', description: is },
            { value: '!=', description: isNot },
          ],
          symbol: '@',
          token: AuthorToken,
          unique: true,
          fetchAuthors,
          preloadedAuthors: this.preloadedAuthors(),
        },
        {
          icon: 'user',
          title: assignee,
          type: 'assignee_username',
          operators: [
            { value: '=', description: is },
            { value: '!=', description: isNot },
          ],
          token: AuthorToken,
          unique: true,
          fetchAuthors,
          preloadedAuthors: this.preloadedAuthors(),
        },
      ];
    },
  },
  methods: {
    preloadedAuthors() {
      return gon?.current_user_id
        ? [
            {
              id: convertToGraphQLId(TYPE_USER, gon.current_user_id),
              name: gon.current_user_fullname,
              username: gon.current_username,
              avatarUrl: gon.current_user_avatar_url,
            },
          ]
        : [];
    },
  },
};
</script>

<template>
  <board-filtered-search data-testid="issue-board-filtered-search" :tokens="tokens" />
</template>
