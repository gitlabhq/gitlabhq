<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { debounce } from 'lodash';
import { __ } from '~/locale';
import { BRANCHES_PER_PAGE } from '../constants';
import getProjectQuery from '../graphql/queries/get_project.query.graphql';

export default {
  BRANCHES_PER_PAGE,
  components: {
    GlCollapsibleListbox,
  },
  props: {
    selectedProject: {
      type: Object,
      required: false,
      default: null,
    },
    selectedBranchName: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      initialSourceBranchNamesLoading: false,
      sourceBranchNamesLoading: false,
      sourceBranchNames: [],
    };
  },
  computed: {
    hasSelectedProject() {
      return Boolean(this.selectedProject);
    },
    hasSelectedSourceBranch() {
      return Boolean(this.selectedBranchName);
    },
    branchDropdownText() {
      return this.selectedBranchName || __('Select a branch');
    },
  },
  watch: {
    selectedProject: {
      immediate: true,
      async handler(selectedProject) {
        if (!selectedProject) return;

        this.initialSourceBranchNamesLoading = true;
        await this.fetchSourceBranchNames({ projectPath: selectedProject.fullPath });
        this.initialSourceBranchNamesLoading = false;
      },
    },
  },
  methods: {
    onSourceBranchSelect(branchName) {
      this.$emit('change', branchName);
    },
    onSearch: debounce(function debouncedSearch(branchSearchQuery) {
      this.onSourceBranchSearchQuery(branchSearchQuery);
    }, 250),
    onSourceBranchSearchQuery(branchSearchQuery) {
      this.branchSearchQuery = branchSearchQuery;
      this.fetchSourceBranchNames({
        projectPath: this.selectedProject.fullPath,
        searchPattern: this.branchSearchQuery,
      });
    },
    onError({ message } = {}) {
      this.$emit('error', { message });
    },
    async fetchSourceBranchNames({ projectPath, searchPattern } = {}) {
      this.sourceBranchNamesLoading = true;
      try {
        const { data } = await this.$apollo.query({
          query: getProjectQuery,
          variables: {
            projectPath,
            branchNamesLimit: this.$options.BRANCHES_PER_PAGE,
            branchNamesOffset: 0,
            branchNamesSearchPattern: searchPattern ? `*${searchPattern}*` : '*',
          },
        });

        const { branchNames, rootRef } = data?.project.repository || {};
        this.sourceBranchNames =
          branchNames.map((value) => {
            return { text: value, value };
          }) || [];

        // Use root ref as the default selection
        if (rootRef && !this.hasSelectedSourceBranch) {
          this.onSourceBranchSelect(rootRef);
        }
      } catch (err) {
        this.onError({
          message: __('Something went wrong while fetching source branches.'),
        });
      } finally {
        this.sourceBranchNamesLoading = false;
      }
    },
  },
};
</script>

<template>
  <gl-collapsible-listbox
    :class="{ 'gl-font-monospace': hasSelectedSourceBranch }"
    :disabled="!hasSelectedProject"
    :items="sourceBranchNames"
    :loading="initialSourceBranchNamesLoading"
    :searchable="true"
    :searching="sourceBranchNamesLoading"
    :toggle-text="branchDropdownText"
    @search="onSearch"
    @select="onSourceBranchSelect"
  />
</template>
