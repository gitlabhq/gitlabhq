<script>
import { GlDropdown, GlDropdownItem, GlSearchBoxByType, GlDropdownSectionHeader } from '@gitlab/ui';
import { debounce } from 'lodash';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { s__ } from '~/locale';

const EMPTY_DROPDOWN_TEXT = s__('CompareRevisions|Select branch/tag');
const SEARCH_DEBOUNCE_MS = 300;

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
    GlDropdownSectionHeader,
    GlSearchBoxByType,
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
      loading: true,
      searchTerm: '',
      selectedRevision: this.getDefaultBranch(),
    };
  },
  computed: {
    hasBranches() {
      return Boolean(this.branches?.length);
    },
    hasTags() {
      return Boolean(this.tags?.length);
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
        .catch(() => {
          createAlert({
            message: s__(
              'CompareRevisions|There was an error while searching the branch/tag list. Please try again.',
            ),
          });
        });
    },
    fetchBranchesAndTags(reset = false) {
      this.loading = true;

      if (reset) {
        this.setSelectedRevision(this.paramsBranch);
      }

      return axios
        .get(this.refsProjectPath)
        .then(({ data }) => {
          this.branches = data.Branches || [];
          this.tags = data.Tags || [];
        })
        .catch(() => {
          createAlert({
            message: s__(
              'CompareRevisions|There was an error while loading the branch/tag list. Please try again.',
            ),
          });
        })
        .finally(() => {
          this.loading = false;
        });
    },
    getDefaultBranch() {
      return this.paramsBranch || EMPTY_DROPDOWN_TEXT;
    },
    onClick(revision) {
      this.setSelectedRevision(revision);
      this.$emit('selectRevision', { direction: this.paramsName, revision });
    },
    onSearchEnter() {
      this.setSelectedRevision(this.searchTerm);
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
    <gl-dropdown
      class="gl-w-full gl-font-monospace"
      toggle-class="form-control compare-dropdown-toggle gl-min-w-0"
      :text="selectedRevision"
      :header-text="s__('CompareRevisions|Select Git revision')"
      :loading="loading"
    >
      <template #header>
        <gl-search-box-by-type
          v-model.trim="searchTerm"
          :placeholder="s__('CompareRevisions|Filter by Git revision')"
          @keyup.enter="onSearchEnter"
        />
      </template>
      <gl-dropdown-section-header v-if="hasBranches">
        {{ s__('CompareRevisions|Branches') }}
      </gl-dropdown-section-header>
      <gl-dropdown-item
        v-for="branch in branches"
        :key="`branch-${branch}`"
        is-check-item
        :is-checked="selectedRevision === branch"
        data-testid="branches-dropdown-item"
        @click="onClick(branch)"
      >
        {{ branch }}
      </gl-dropdown-item>
      <gl-dropdown-section-header v-if="hasTags">
        {{ s__('CompareRevisions|Tags') }}
      </gl-dropdown-section-header>
      <gl-dropdown-item
        v-for="tag in tags"
        :key="`tag-${tag}`"
        is-check-item
        :is-checked="selectedRevision === tag"
        data-testid="tags-dropdown-item"
        @click="onClick(tag)"
      >
        {{ tag }}
      </gl-dropdown-item>
    </gl-dropdown>
  </div>
</template>
