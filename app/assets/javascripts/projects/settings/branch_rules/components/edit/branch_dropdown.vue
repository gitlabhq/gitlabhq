<script>
import {
  GlDropdown,
  GlDropdownItem,
  GlDropdownDivider,
  GlSearchBoxByType,
  GlSprintf,
  GlLink,
} from '@gitlab/ui';
import { createAlert } from '~/alert';
import { s__, sprintf } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import branchesQuery from '../../queries/branches.query.graphql';

export const i18n = {
  fetchBranchesError: s__('BranchRules|An error occurred while fetching branches.'),
  noMatch: s__('BranchRules|No matching results'),
  branchHelpText: s__(
    'BranchRules|%{linkStart}Wildcards%{linkEnd} such as *-stable or production/* are supported.',
  ),
  wildCardSearchHelp: s__('BranchRules|Create wildcard: %{searchTerm}'),
};

export default {
  i18n,
  name: 'BranchDropdown',
  components: {
    GlDropdown,
    GlDropdownItem,
    GlDropdownDivider,
    GlSearchBoxByType,
    GlSprintf,
    GlLink,
  },
  apollo: {
    branchNames: {
      query: branchesQuery,
      variables() {
        return {
          projectPath: this.projectPath,
          searchPattern: `*${this.searchTerm}*`,
        };
      },
      update({ project: { repository = {} } } = {}) {
        return repository.branchNames || [];
      },
      error(e) {
        createAlert({
          message: this.$options.i18n.fetchBranchesError,
          captureError: true,
          error: e,
        });
      },
    },
  },
  searchInputDelay: 250,
  wildcardsHelpPath: helpPagePath('user/project/repository/branches/protected', {
    anchor: 'protect-multiple-branches-with-wildcard-rules',
  }),
  props: {
    projectPath: {
      type: String,
      required: true,
    },
    value: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      searchTerm: '',
      branchNames: [],
    };
  },
  computed: {
    createButtonLabel() {
      return sprintf(this.$options.i18n.wildCardSearchHelp, {
        searchTerm: this.searchTerm,
      });
    },
    shouldRenderCreateButton() {
      return this.searchTerm && !this.branchNames.includes(this.searchTerm);
    },
    isLoading() {
      return this.$apollo.queries.branchNames.loading;
    },
  },
  methods: {
    selectBranch(selected) {
      this.$emit('input', selected);
    },
    createWildcard() {
      this.$emit('createWildcard', this.searchTerm);
    },
    isSelected(branch) {
      return this.value === branch;
    },
  },
};
</script>
<template>
  <div>
    <gl-dropdown :text="value || branchNames[0]" class="gl-w-full">
      <gl-search-box-by-type
        v-model.trim="searchTerm"
        data-testid="branch-search"
        :debounce="$options.searchInputDelay"
        :is-loading="isLoading"
      />
      <gl-dropdown-item
        v-for="branch in branchNames"
        :key="branch"
        :is-checked="isSelected(branch)"
        is-check-item
        @click="selectBranch(branch)"
      >
        {{ branch }}
      </gl-dropdown-item>
      <gl-dropdown-item v-if="!branchNames.length && !isLoading" data-testid="no-data">{{
        $options.i18n.noMatch
      }}</gl-dropdown-item>
      <template v-if="shouldRenderCreateButton">
        <gl-dropdown-divider />
        <gl-dropdown-item data-testid="create-wildcard-button" @click="createWildcard">
          {{ createButtonLabel }}
        </gl-dropdown-item>
      </template>
    </gl-dropdown>
    <gl-sprintf :message="$options.i18n.branchHelpText">
      <template #link="{ content }">
        <gl-link :href="$options.wildcardsHelpPath">{{ content }}</gl-link>
      </template>
    </gl-sprintf>
  </div>
</template>
