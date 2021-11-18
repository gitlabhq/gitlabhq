<script>
import { GlFilteredSearchToken } from '@gitlab/ui';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { mapActions } from 'vuex';
import BoardFilteredSearch from 'ee_else_ce/boards/components/board_filtered_search.vue';
import { BoardType } from '~/boards/constants';
import axios from '~/lib/utils/axios_utils';
import issueBoardFilters from '~/boards/issue_board_filters';
import { TYPE_USER } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { __ } from '~/locale';
import {
  DEFAULT_MILESTONES_GRAPHQL,
  TOKEN_TITLE_MY_REACTION,
} from '~/vue_shared/components/filtered_search_bar/constants';
import AuthorToken from '~/vue_shared/components/filtered_search_bar/tokens/author_token.vue';
import EmojiToken from '~/vue_shared/components/filtered_search_bar/tokens/emoji_token.vue';
import LabelToken from '~/vue_shared/components/filtered_search_bar/tokens/label_token.vue';
import MilestoneToken from '~/vue_shared/components/filtered_search_bar/tokens/milestone_token.vue';
import WeightToken from '~/vue_shared/components/filtered_search_bar/tokens/weight_token.vue';

export default {
  types: {
    ISSUE: 'ISSUE',
    INCIDENT: 'INCIDENT',
  },
  i18n: {
    search: __('Search'),
    epic: __('Epic'),
    label: __('Label'),
    author: __('Author'),
    assignee: __('Assignee'),
    type: __('Type'),
    incident: __('Incident'),
    issue: __('Issue'),
    milestone: __('Milestone'),
    weight: __('Weight'),
    is: __('is'),
    isNot: __('is not'),
  },
  components: { BoardFilteredSearch },
  inject: ['isSignedIn'],
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
    isGroupBoard() {
      return this.boardType === BoardType.group;
    },
    epicsGroupPath() {
      return this.isGroupBoard
        ? this.fullPath
        : this.fullPath.slice(0, this.fullPath.lastIndexOf('/'));
    },
    tokensCE() {
      const {
        label,
        is,
        isNot,
        author,
        assignee,
        issue,
        incident,
        type,
        milestone,
        weight,
      } = this.$options.i18n;
      const { types } = this.$options;
      const { fetchAuthors, fetchLabels } = issueBoardFilters(
        this.$apollo,
        this.fullPath,
        this.boardType,
      );

      return [
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
        ...(this.isSignedIn
          ? [
              {
                type: 'my_reaction_emoji',
                title: TOKEN_TITLE_MY_REACTION,
                icon: 'thumb-up',
                token: EmojiToken,
                unique: true,
                fetchEmojis: (search = '') => {
                  // TODO: Switch to GraphQL query when backend is ready: https://gitlab.com/gitlab-org/gitlab/-/issues/339694
                  return axios
                    .get(`${gon.relative_url_root || ''}/-/autocomplete/award_emojis`)
                    .then(({ data }) => {
                      if (search) {
                        return {
                          data: fuzzaldrinPlus.filter(data, search, {
                            key: ['name'],
                          }),
                        };
                      }
                      return { data };
                    });
                },
              },
            ]
          : []),
        {
          type: 'milestone_title',
          title: milestone,
          icon: 'clock',
          symbol: '%',
          token: MilestoneToken,
          unique: true,
          defaultMilestones: DEFAULT_MILESTONES_GRAPHQL,
          fetchMilestones: this.fetchMilestones,
        },
        {
          icon: 'issues',
          title: type,
          type: 'types',
          token: GlFilteredSearchToken,
          unique: true,
          options: [
            { icon: 'issue-type-issue', value: types.ISSUE, title: issue },
            { icon: 'issue-type-incident', value: types.INCIDENT, title: incident },
          ],
        },
        {
          type: 'weight',
          title: weight,
          icon: 'weight',
          token: WeightToken,
          unique: true,
        },
      ];
    },
    tokens() {
      return this.tokensCE;
    },
  },
  methods: {
    ...mapActions(['fetchMilestones']),
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
