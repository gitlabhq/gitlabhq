<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { debounce } from 'lodash';
import { __ } from '~/locale';
import { logError } from '~/lib/logger';

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
      sourceBranchNamesLoadingMore: false,
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
    hasMoreBranches() {
      return (
        this.sourceBranchNames.length > 0 && this.sourceBranchNames.length % BRANCHES_PER_PAGE === 0
      );
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
    async onSourceBranchSearchQuery(branchSearchQuery) {
      this.branchSearchQuery = branchSearchQuery;
      this.sourceBranchNamesLoading = true;

      await this.fetchSourceBranchNames({
        projectPath: this.selectedProject.fullPath,
        searchPattern: this.branchSearchQuery,
      });
      this.sourceBranchNamesLoading = false;
    },
    async onBottomReached() {
      this.sourceBranchNamesLoadingMore = true;

      await this.fetchSourceBranchNames({
        projectPath: this.selectedProject.fullPath,
        searchPattern: this.branchSearchQuery,
        append: true,
      });

      this.sourceBranchNamesLoadingMore = false;
    },
    onError({ message } = {}) {
      this.$emit('error', { message });
    },
    async fetchSourceBranchNames({ projectPath, searchPattern, append = false } = {}) {
      try {
        const { data } = await this.$apollo.query({
          query: getProjectQuery,
          variables: {
            projectPath,
            branchNamesLimit: this.$options.BRANCHES_PER_PAGE,
            branchNamesOffset: append ? this.sourceBranchNames.length : 0,
            branchNamesSearchPattern: searchPattern ? `*${searchPattern}*` : '*',
          },
        });

        const { branchNames, rootRef } = data?.project.repository || {};
        const branchNameItems =
          branchNames?.map((value) => {
            return { text: value, value };
          }) || [];

        if (append) {
          this.sourceBranchNames.push(...branchNameItems);
        } else {
          this.sourceBranchNames = branchNameItems;

          // Use root ref as the default selection
          if (rootRef && !this.hasSelectedSourceBranch) {
            this.onSourceBranchSelect(rootRef);
          }
        }
      } catch (err) {
        logError(err);
        this.onError({
          message: __('Something went wrong while fetching source branches.'),
        });
      }
    },
  },
};
</script>

<template>
  <gl-collapsible-listbox
    :class="{ 'gl-font-monospace': hasSelectedSourceBranch }"
    :selected="selectedBranchName"
    :disabled="!hasSelectedProject"
    :items="sourceBranchNames"
    :loading="initialSourceBranchNamesLoading"
    :searchable="true"
    :searching="sourceBranchNamesLoading"
    :toggle-text="branchDropdownText"
    fluid-width
    :infinite-scroll="hasMoreBranches"
    :infinite-scroll-loading="sourceBranchNamesLoadingMore"
    @bottom-reached="onBottomReached"
    @search="onSearch"
    @select="onSourceBranchSelect"
  />
</template>
