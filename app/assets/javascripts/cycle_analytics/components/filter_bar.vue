<script>
import { mapActions, mapState } from 'vuex';
import {
  OPERATORS_IS,
  DEFAULT_NONE_ANY,
  TOKEN_TITLE_ASSIGNEE,
  TOKEN_TITLE_AUTHOR,
  TOKEN_TITLE_LABEL,
  TOKEN_TITLE_MILESTONE,
} from '~/vue_shared/components/filtered_search_bar/constants';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import {
  prepareTokens,
  processFilters,
  filterToQueryObject,
} from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';
import AuthorToken from '~/vue_shared/components/filtered_search_bar/tokens/author_token.vue';
import LabelToken from '~/vue_shared/components/filtered_search_bar/tokens/label_token.vue';
import MilestoneToken from '~/vue_shared/components/filtered_search_bar/tokens/milestone_token.vue';
import UrlSync from '~/vue_shared/components/url_sync.vue';

export default {
  name: 'FilterBar',
  components: {
    FilteredSearchBar,
    UrlSync,
  },
  props: {
    groupPath: {
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
          icon: 'clock',
          title: TOKEN_TITLE_MILESTONE,
          type: 'milestone',
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
          type: 'labels',
          token: LabelToken,
          defaultLabels: DEFAULT_NONE_ANY,
          initialLabels: this.labelsData,
          unique: false,
          symbol: '~',
          operators: OPERATORS_IS,
          fetchLabels: this.fetchLabels,
        },
        {
          icon: 'pencil',
          title: TOKEN_TITLE_AUTHOR,
          type: 'author',
          token: AuthorToken,
          initialAuthors: this.authorsData,
          unique: true,
          operators: OPERATORS_IS,
          fetchAuthors: this.fetchAuthors,
        },
        {
          icon: 'user',
          title: TOKEN_TITLE_ASSIGNEE,
          type: 'assignees',
          token: AuthorToken,
          initialAuthors: this.assigneesData,
          unique: false,
          operators: OPERATORS_IS,
          fetchAuthors: this.fetchAssignees,
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
        milestone: this.selectedMilestone,
        author: this.selectedAuthor,
        assignees: this.selectedAssigneeList,
        labels: this.selectedLabelList,
      });
    },
    handleFilter(filters) {
      const { labels, milestone, author, assignees } = processFilters(filters);

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
      class="gl-flex-grow-1"
      :namespace="groupPath"
      recent-searches-storage-key="value-stream-analytics"
      :search-input-placeholder="__('Filter results')"
      :tokens="tokens"
      :initial-filter-value="initialFilterValue()"
      @onFilter="handleFilter"
    />
    <url-sync :query="query" />
  </div>
</template>
