<script>
import { GlCollapsibleListbox, GlBadge } from '@gitlab/ui';
import { produce } from 'immer';
import { createAlert } from '~/alert';
import { __, s__ } from '~/locale';
import getBranchesOptionsQuery from '../graphql/queries/get_branches_options.query.graphql';

const BRANCH_PAGINATION_LIMIT = 10;

export default {
  components: {
    GlCollapsibleListbox,
    GlBadge,
  },
  model: {
    prop: 'selected',
    event: 'select',
  },
  props: {
    id: {
      type: String,
      required: false,
      default: null,
    },
    block: {
      type: Boolean,
      required: false,
      default: false,
    },
    selected: {
      type: String,
      required: false,
      default: null,
    },
    defaultBranch: {
      type: String,
      required: false,
      default: null,
    },
    projectPath: {
      type: String,
      required: true,
    },
    projectBranchCount: {
      type: Number,
      required: true,
      default: 0,
    },
  },
  data() {
    return {
      branchesOptions: [],
      branch: this.selected,
      page: 0,
      searchTerm: '',
    };
  },
  apollo: {
    branchesOptions: {
      query: getBranchesOptionsQuery,
      variables() {
        return {
          offset: 0,
          fullPath: this.projectPath,
          limit: BRANCH_PAGINATION_LIMIT,
          searchPattern: this.searchTerm ? `*${this.searchTerm}*` : '*',
        };
      },
      update(data) {
        return data.project?.repository?.branchNames || [];
      },
      result() {
        this.page += 1;
      },
      error(error) {
        this.onFetchError(error);
      },
    },
  },
  computed: {
    infiniteScroll() {
      return this.branchesOptions.length > 0;
    },
    items() {
      return [
        {
          text: s__('PipelineCharts|All branches'),
          value: '', // use '' to represent no value selected, as GlCollapsibleListbox does not accept null as a valid value
        },
        ...this.branchesOptions.map((branch) => ({
          text: branch,
          value: branch,
        })),
      ];
    },
    loading() {
      return this.$apollo.queries.branchesOptions.loading;
    },
  },
  methods: {
    onSelect(branch) {
      this.$emit(this.$options.model.event, branch);
    },
    onSearch(newSearchTerm) {
      this.searchTerm = newSearchTerm.trim();
      this.page = 0;
    },
    onBottomReached() {
      if (
        this.loading ||
        this.searchTerm.length > 0 ||
        this.branchesOptions.length >= this.projectBranchCount
      ) {
        return;
      }

      this.$apollo.queries.branchesOptions
        .fetchMore({
          variables: {
            offset: this.page * BRANCH_PAGINATION_LIMIT,
          },
          updateQuery(previousResult, { fetchMoreResult }) {
            const currentBranches = previousResult.project.repository.branchNames;
            const newBranches = fetchMoreResult.project.repository.branchNames;

            return produce(fetchMoreResult, (draftData) => {
              draftData.project.repository.branchNames = currentBranches.concat(newBranches);
            });
          },
        })
        .catch((error) => {
          this.onFetchError(error);
        });
    },
    onFetchError(error) {
      createAlert({
        message: __('Unable to fetch branch list for this project.'),
        captureError: true,
        error,
      });
    },
  },
};
</script>

<template>
  <gl-collapsible-listbox
    :id="id"
    v-model="branch"
    searchable
    :block="block"
    :items="items"
    :title="__('Switch branch')"
    :toggle-text="branch"
    :search-placeholder="s__('Branches|Filter by branch name')"
    :infinite-scroll-loading="loading"
    :infinite-scroll="infiniteScroll"
    @select="onSelect"
    @search="onSearch"
    @bottom-reached="onBottomReached"
  >
    <template #list-item="{ item }">
      {{ item.text }}
      <gl-badge v-if="item.value === defaultBranch">{{ s__('Branches|default') }}</gl-badge>
    </template>
  </gl-collapsible-listbox>
</template>
