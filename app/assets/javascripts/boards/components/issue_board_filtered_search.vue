<script>
import { GlFilteredSearchToken } from '@gitlab/ui';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { orderBy } from 'lodash';
import BoardFilteredSearch from 'ee_else_ce/boards/components/board_filtered_search.vue';
import axios from '~/lib/utils/axios_utils';
import { joinPaths } from '~/lib/utils/url_utility';
import issueBoardFilters from 'ee_else_ce/boards/issue_board_filters';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { __ } from '~/locale';
import {
  OPERATORS_IS_NOT,
  OPERATORS_IS,
  TOKEN_TITLE_ASSIGNEE,
  TOKEN_TITLE_AUTHOR,
  TOKEN_TITLE_CONFIDENTIAL,
  TOKEN_TITLE_LABEL,
  TOKEN_TITLE_MILESTONE,
  TOKEN_TITLE_MY_REACTION,
  TOKEN_TITLE_RELEASE,
  TOKEN_TITLE_TYPE,
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_CONFIDENTIAL,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MILESTONE,
  TOKEN_TYPE_MY_REACTION,
  TOKEN_TYPE_RELEASE,
  TOKEN_TYPE_TYPE,
} from '~/vue_shared/components/filtered_search_bar/constants';
import UserToken from '~/vue_shared/components/filtered_search_bar/tokens/user_token.vue';
import EmojiToken from '~/vue_shared/components/filtered_search_bar/tokens/emoji_token.vue';
import LabelToken from '~/vue_shared/components/filtered_search_bar/tokens/label_token.vue';
import MilestoneToken from '~/vue_shared/components/filtered_search_bar/tokens/milestone_token.vue';
import ReleaseToken from '~/vue_shared/components/filtered_search_bar/tokens/release_token.vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  types: {
    ISSUE: 'ISSUE',
    INCIDENT: 'INCIDENT',
    TASK: 'TASK',
  },
  i18n: {
    incident: __('Incident'),
    issue: __('Issue'),
    task: __('Task'),
  },
  components: { BoardFilteredSearch },
  mixins: [glFeatureFlagMixin()],
  inject: ['isSignedIn', 'releasesFetchPath', 'fullPath', 'isGroupBoard'],
  props: {
    board: {
      type: Object,
      required: false,
      default: () => {},
    },
    isSwimlanesOn: {
      type: Boolean,
      required: false,
      default: false,
    },
    filters: {
      type: Object,
      required: true,
    },
  },
  computed: {
    tokensCE() {
      const { issue, incident, task } = this.$options.i18n;
      const { types } = this.$options;
      const { fetchLabels } = issueBoardFilters(this.$apollo, this.fullPath, this.isGroupBoard);

      const typeOptions = [
        { icon: 'issue-type-issue', value: types.ISSUE, title: issue },
        { icon: 'issue-type-incident', value: types.INCIDENT, title: incident },
      ];

      if (this.glFeatures.workItemsBeta) {
        typeOptions.push({ icon: 'issue-type-task', value: types.TASK, title: task });
      }

      const tokens = [
        {
          icon: 'user',
          title: TOKEN_TITLE_ASSIGNEE,
          type: TOKEN_TYPE_ASSIGNEE,
          operators: OPERATORS_IS_NOT,
          token: UserToken,
          dataType: 'user',
          unique: true,
          isProject: !this.isGroupBoard,
          fullPath: this.fullPath,
          preloadedUsers: this.preloadedUsers(),
        },
        {
          icon: 'pencil',
          title: TOKEN_TITLE_AUTHOR,
          type: TOKEN_TYPE_AUTHOR,
          operators: OPERATORS_IS_NOT,
          symbol: '@',
          token: UserToken,
          dataType: 'user',
          unique: true,
          isProject: !this.isGroupBoard,
          fullPath: this.fullPath,
          preloadedUsers: this.preloadedUsers(),
        },
        {
          icon: 'labels',
          title: TOKEN_TITLE_LABEL,
          type: TOKEN_TYPE_LABEL,
          operators: OPERATORS_IS_NOT,
          token: LabelToken,
          unique: false,
          recentSuggestionsStorageKey: `${this.fullPath}-board-recent-tokens-label`,
          symbol: '~',
          fetchLabels,
        },
        ...(this.isSignedIn
          ? [
              {
                type: TOKEN_TYPE_MY_REACTION,
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
              {
                type: TOKEN_TYPE_CONFIDENTIAL,
                icon: 'eye-slash',
                title: TOKEN_TITLE_CONFIDENTIAL,
                unique: true,
                token: GlFilteredSearchToken,
                operators: OPERATORS_IS,
                options: [
                  { icon: 'eye-slash', value: 'yes', title: __('Yes') },
                  { icon: 'eye', value: 'no', title: __('No') },
                ],
              },
            ]
          : []),
        {
          type: TOKEN_TYPE_MILESTONE,
          title: TOKEN_TITLE_MILESTONE,
          icon: 'milestone',
          symbol: '%',
          token: MilestoneToken,
          unique: true,
          shouldSkipSort: true,
          isProject: !this.isGroupBoard,
          fullPath: this.fullPath,
        },
        {
          icon: 'issues',
          title: TOKEN_TITLE_TYPE,
          type: TOKEN_TYPE_TYPE,
          token: GlFilteredSearchToken,
          unique: true,
          options: typeOptions,
        },
        {
          type: TOKEN_TYPE_RELEASE,
          title: TOKEN_TITLE_RELEASE,
          icon: 'rocket',
          token: ReleaseToken,
          fetchReleases: (search) => {
            // TODO: Switch to GraphQL query when backend is ready: https://gitlab.com/gitlab-org/gitlab/-/issues/337686
            return axios
              .get(joinPaths(gon.relative_url_root, this.releasesFetchPath))
              .then(({ data }) => {
                if (search) {
                  return fuzzaldrinPlus.filter(data, search, {
                    key: ['tag'],
                  });
                }
                return data;
              });
          },
        },
      ];

      return orderBy(tokens, ['title']);
    },
    tokens() {
      return this.tokensCE;
    },
  },
  methods: {
    preloadedUsers() {
      return gon?.current_user_id
        ? [
            {
              id: convertToGraphQLId(TYPENAME_USER, gon.current_user_id),
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
  <board-filtered-search
    data-testid="issue-board-filtered-search"
    :tokens="tokens"
    :board="board"
    :is-swimlanes-on="isSwimlanesOn"
    :filters="filters"
    @setFilters="$emit('setFilters', $event)"
  />
</template>
