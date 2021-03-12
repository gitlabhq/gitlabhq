<script>
import { GlDropdown, GlDropdownItem, GlSearchBoxByType, GlDropdownSectionHeader } from '@gitlab/ui';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { s__ } from '~/locale';

const emptyDropdownText = s__('CompareRevisions|Select branch/tag');

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
    filteredBranches() {
      return this.branches.filter((branch) =>
        branch.toLowerCase().includes(this.searchTerm.toLowerCase()),
      );
    },
    hasFilteredBranches() {
      return this.filteredBranches.length;
    },
    filteredTags() {
      return this.tags.filter((tag) => tag.toLowerCase().includes(this.searchTerm.toLowerCase()));
    },
    hasFilteredTags() {
      return this.filteredTags.length;
    },
  },
  watch: {
    refsProjectPath(newRefsProjectPath, oldRefsProjectPath) {
      if (newRefsProjectPath !== oldRefsProjectPath) {
        this.fetchBranchesAndTags(true);
      }
    },
  },
  mounted() {
    this.fetchBranchesAndTags();
  },
  methods: {
    fetchBranchesAndTags(reset = false) {
      const endpoint = this.refsProjectPath;
      this.loading = true;

      if (reset) {
        this.selectedRevision = this.getDefaultBranch();
      }

      return axios
        .get(endpoint)
        .then(({ data }) => {
          this.branches = data.Branches || [];
          this.tags = data.Tags || [];
        })
        .catch(() => {
          createFlash({
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
      return this.paramsBranch || emptyDropdownText;
    },
    onClick(revision) {
      this.selectedRevision = revision;
    },
    onSearchEnter() {
      this.selectedRevision = this.searchTerm;
    },
  },
};
</script>

<template>
  <div :class="`js-compare-${paramsName}-dropdown`">
    <input type="hidden" :name="paramsName" :value="selectedRevision" />
    <gl-dropdown
      class="gl-w-full gl-font-monospace"
      toggle-class="form-control compare-dropdown-toggle js-compare-dropdown gl-min-w-0"
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
      <gl-dropdown-section-header v-if="hasFilteredBranches">
        {{ s__('CompareRevisions|Branches') }}
      </gl-dropdown-section-header>
      <gl-dropdown-item
        v-for="(branch, index) in filteredBranches"
        :key="`branch${index}`"
        is-check-item
        :is-checked="selectedRevision === branch"
        @click="onClick(branch)"
      >
        {{ branch }}
      </gl-dropdown-item>
      <gl-dropdown-section-header v-if="hasFilteredTags">
        {{ s__('CompareRevisions|Tags') }}
      </gl-dropdown-section-header>
      <gl-dropdown-item
        v-for="(tag, index) in filteredTags"
        :key="`tag${index}`"
        is-check-item
        :is-checked="selectedRevision === tag"
        @click="onClick(tag)"
      >
        {{ tag }}
      </gl-dropdown-item>
    </gl-dropdown>
  </div>
</template>
