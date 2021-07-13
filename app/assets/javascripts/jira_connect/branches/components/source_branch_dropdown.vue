<script>
import { GlDropdown, GlDropdownItem, GlSearchBoxByType, GlLoadingIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import { BRANCHES_PER_PAGE } from '../constants';
import getProjectQuery from '../graphql/queries/get_project.query.graphql';

export default {
  BRANCHES_PER_PAGE,
  components: {
    GlDropdown,
    GlDropdownItem,
    GlSearchBoxByType,
    GlLoadingIcon,
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
      sourceBranchSearchQuery: '',
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
        this.sourceBranchNames = branchNames || [];

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
  <gl-dropdown
    :text="branchDropdownText"
    :loading="initialSourceBranchNamesLoading"
    :disabled="!hasSelectedProject"
    :class="{ 'gl-font-monospace': hasSelectedSourceBranch }"
  >
    <template #header>
      <gl-search-box-by-type
        :debounce="250"
        :value="sourceBranchSearchQuery"
        @input="onSourceBranchSearchQuery"
      />
    </template>

    <gl-loading-icon v-show="sourceBranchNamesLoading" />
    <template v-if="!sourceBranchNamesLoading">
      <gl-dropdown-item
        v-for="branchName in sourceBranchNames"
        v-show="!sourceBranchNamesLoading"
        :key="branchName"
        :is-checked="branchName === selectedBranchName"
        is-check-item
        class="gl-font-monospace"
        @click="onSourceBranchSelect(branchName)"
      >
        {{ branchName }}
      </gl-dropdown-item>
    </template>
  </gl-dropdown>
</template>
