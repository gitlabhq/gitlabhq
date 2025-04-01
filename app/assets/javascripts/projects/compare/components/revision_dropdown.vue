<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { debounce } from 'lodash';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { s__ } from '~/locale';
import { logError } from '~/lib/logger';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { ENTER_KEY } from '~/lib/utils/keys';

const EMPTY_DROPDOWN_TEXT = s__('CompareRevisions|Select branch/tag');
const SEARCH_DEBOUNCE_MS = 300;

export default {
  components: {
    GlCollapsibleListbox,
  },
  props: {
    refsProjectPath: {
      type: String,
      required: true,
    },
    paramsName: {
      type: String,
      required: true,
    },
    paramsBranch: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      branches: [],
      tags: [],
      isLoadingBranchesAndTags: true,
      isLoadingSearch: false,
      searchTerm: '',
      selectedRevision: this.getDefaultBranch(),
    };
  },
  computed: {
    hasBranches() {
      return this.branches?.length > 0;
    },
    hasTags() {
      return this.tags?.length > 0;
    },
    dropdownItems() {
      return [
        ...(this.hasBranches
          ? [
              {
                text: s__('CompareRevisions|Branches'),
                options: this.branches.map((branch) => ({ text: branch, value: branch })),
              },
            ]
          : []),
        ...(this.hasTags
          ? [
              {
                text: s__('CompareRevisions|Tags'),
                options: this.tags.map((tag) => ({ text: tag, value: tag })),
              },
            ]
          : []),
      ];
    },
    searchInputElement() {
      const listbox = this.$refs.collapsibleDropdown;
      const { searchBox } = listbox.$refs;
      return searchBox.$refs.input;
    },
  },
  watch: {
    refsProjectPath(newRefsProjectPath, oldRefsProjectPath) {
      if (newRefsProjectPath !== oldRefsProjectPath) {
        this.fetchBranchesAndTags(true);
      }
    },
    searchTerm: debounce(function debounceSearch() {
      this.searchBranchesAndTags();
    }, SEARCH_DEBOUNCE_MS),
    paramsBranch(newBranch) {
      this.setSelectedRevision(newBranch);
    },
  },
  mounted() {
    this.fetchBranchesAndTags();
  },
  methods: {
    searchBranchesAndTags() {
      this.isLoadingSearch = true;

      return axios
        .get(this.refsProjectPath, {
          params: {
            search: this.searchTerm,
          },
        })
        .then(({ data }) => {
          this.branches = data.Branches || [];
          this.tags = data.Tags || [];
        })
        .catch((e) => {
          Sentry.captureException(e);
          logError(`There was an error while searching the branch/tag list.`, e);
          createAlert({
            message: s__(
              'CompareRevisions|There was an error while searching the branch/tag list. Please try again.',
            ),
          });
        })
        .finally(() => {
          this.isLoadingSearch = false;
        });
    },
    fetchBranchesAndTags(reset = false) {
      this.isLoadingBranchesAndTags = true;

      if (reset) {
        this.setSelectedRevision(this.paramsBranch);
      }

      return axios
        .get(this.refsProjectPath)
        .then(({ data }) => {
          this.branches = data.Branches || [];
          this.tags = data.Tags || [];
        })
        .catch((e) => {
          Sentry.captureException(e);
          logError(`There was an error while loading the branch/tag list. Please try again.`, e);
          createAlert({
            message: s__(
              'CompareRevisions|There was an error while loading the branch/tag list. Please try again.',
            ),
          });
        })
        .finally(() => {
          this.isLoadingBranchesAndTags = false;
        });
    },
    getDefaultBranch() {
      return this.paramsBranch || EMPTY_DROPDOWN_TEXT;
    },
    onClick(revision) {
      this.setSelectedRevision(revision);
      this.$emit('selectRevision', { direction: this.paramsName, revision });
    },
    handleKeyDown(e) {
      // temporary hacks to support searching for commits on enter
      // more elegant solution comes up in https://gitlab.com/gitlab-org/gitlab/-/issues/525192
      const { code, target } = e;
      if (code === ENTER_KEY) {
        this.setSelectedRevision(target.value);
        const listbox = this.$refs.collapsibleDropdown;
        const dropdown = listbox.$refs.baseDropdown;
        dropdown.close();
      }
    },
    onShown() {
      this.searchInputElement.addEventListener('keydown', this.handleKeyDown);
    },
    onHidden() {
      this.searchInputElement.removeEventListener('keydown', this.handleKeyDown);
    },
    setSelectedRevision(revision) {
      this.selectedRevision = revision || EMPTY_DROPDOWN_TEXT;
    },
  },
};
</script>

<template>
  <div :class="`js-compare-${paramsName}-dropdown`">
    <input type="hidden" :name="paramsName" :value="selectedRevision" />
    <gl-collapsible-listbox
      ref="collapsibleDropdown"
      block
      searchable
      class="gl-w-full gl-font-monospace"
      toggle-class="form-control compare-dropdown-toggle gl-min-w-0"
      :items="dropdownItems"
      :toggle-text="selectedRevision"
      :header-text="s__('CompareRevisions|Select Git revision')"
      :loading="isLoadingBranchesAndTags"
      :searching="isLoadingSearch"
      :search-placeholder="s__('CompareRevisions|Filter by Git revision')"
      no-results-text=""
      @shown="onShown"
      @hidden="onHidden"
      @search="searchTerm = $event"
      @select="onClick"
    />
  </div>
</template>
