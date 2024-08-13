<script>
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState } from 'vuex';
import {
  OPERATORS_IS,
  OPTIONS_NONE_ANY,
  TOKEN_TITLE_ASSIGNEE,
  TOKEN_TITLE_AUTHOR,
  TOKEN_TITLE_LABEL,
  TOKEN_TITLE_MILESTONE,
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MILESTONE,
} from '~/vue_shared/components/filtered_search_bar/constants';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import {
  prepareTokens,
  processFilters,
  filterToQueryObject,
} from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';
import UserToken from '~/vue_shared/components/filtered_search_bar/tokens/user_token.vue';
import LabelToken from '~/vue_shared/components/filtered_search_bar/tokens/label_token.vue';
import MilestoneToken from '~/vue_shared/components/filtered_search_bar/tokens/milestone_token.vue';
import UrlSync from '~/vue_shared/components/url_sync.vue';
import { MAX_LABELS } from '../constants';

export default {
  name: 'FilterBar',
  components: {
    FilteredSearchBar,
    UrlSync,
  },
  props: {
    namespacePath: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState('filters', {
      selectedMilestone: (state) => state.milestones.selected,
      selectedAuthor: (state) => state.authors.selected,
      selectedLabelList: (state) => state.labels.selectedList,
      selectedAssigneeList: (state) => state.assignees.selectedList,
      milestonesData: (state) => state.milestones.data,
      labelsData: (state) => state.labels.data,
      authorsData: (state) => state.authors.data,
      assigneesData: (state) => state.assignees.data,
    }),
    tokens() {
      return [
        {
          icon: 'milestone',
          title: TOKEN_TITLE_MILESTONE,
          type: TOKEN_TYPE_MILESTONE,
          token: MilestoneToken,
          initialMilestones: this.milestonesData,
          unique: true,
          symbol: '%',
          operators: OPERATORS_IS,
          fetchMilestones: this.fetchMilestones,
        },
        {
          icon: 'labels',
          title: TOKEN_TITLE_LABEL,
          type: TOKEN_TYPE_LABEL,
          token: LabelToken,
          defaultLabels: OPTIONS_NONE_ANY,
          initialLabels: this.labelsData,
          unique: false,
          symbol: '~',
          operators: OPERATORS_IS,
          fetchLabels: this.fetchLabels,
          maxSuggestions: MAX_LABELS,
        },
        {
          icon: 'pencil',
          title: TOKEN_TITLE_AUTHOR,
          type: TOKEN_TYPE_AUTHOR,
          token: UserToken,
          dataType: 'user',
          initialUsers: this.authorsData,
          unique: true,
          operators: OPERATORS_IS,
          fetchUsers: this.fetchAuthors,
        },
        {
          icon: 'user',
          title: TOKEN_TITLE_ASSIGNEE,
          type: TOKEN_TYPE_ASSIGNEE,
          token: UserToken,
          dataType: 'user',
          initialUsers: this.assigneesData,
          unique: false,
          operators: OPERATORS_IS,
          fetchUsers: this.fetchAssignees,
        },
      ];
    },
    query() {
      return filterToQueryObject({
        milestone_title: this.selectedMilestone,
        author_username: this.selectedAuthor,
        label_name: this.selectedLabelList,
        assignee_username: this.selectedAssigneeList,
      });
    },
  },
  methods: {
    ...mapActions('filters', [
      'setFilters',
      'fetchMilestones',
      'fetchLabels',
      'fetchAuthors',
      'fetchAssignees',
    ]),
    initialFilterValue() {
      return prepareTokens({
        [TOKEN_TYPE_MILESTONE]: this.selectedMilestone,
        [TOKEN_TYPE_AUTHOR]: this.selectedAuthor,
        [TOKEN_TYPE_ASSIGNEE]: this.selectedAssigneeList,
        [TOKEN_TYPE_LABEL]: this.selectedLabelList,
      });
    },
    handleFilter(filters) {
      const {
        [TOKEN_TYPE_LABEL]: labels,
        [TOKEN_TYPE_MILESTONE]: milestone,
        [TOKEN_TYPE_AUTHOR]: author,
        [TOKEN_TYPE_ASSIGNEE]: assignees,
      } = processFilters(filters);

      this.setFilters({
        selectedAuthor: author ? author[0] : null,
        selectedMilestone: milestone ? milestone[0] : null,
        selectedAssigneeList: assignees || [],
        selectedLabelList: labels || [],
      });
    },
  },
};
</script>

<template>
  <div>
    <filtered-search-bar
      class="gl-grow"
      :namespace="namespacePath"
      recent-searches-storage-key="value-stream-analytics"
      :search-input-placeholder="__('Filter results')"
      :tokens="tokens"
      :initial-filter-value="initialFilterValue()"
      terms-as-tokens
      @onFilter="handleFilter"
    />
    <url-sync :query="query" />
  </div>
</template>
