<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import {
  GlDropdown,
  GlDropdownDivider,
  GlDropdownSectionHeader,
  GlSearchBoxByType,
  GlSprintf,
  GlIcon,
  GlLoadingIcon,
} from '@gitlab/ui';
import { debounce } from 'lodash';
import createStore from '../stores';
import { SEARCH_DEBOUNCE_MS, DEFAULT_I18N } from '../constants';
import RefResultsSection from './ref_results_section.vue';

export default {
  name: 'RefSelector',
  store: createStore(),
  components: {
    GlDropdown,
    GlDropdownDivider,
    GlDropdownSectionHeader,
    GlSearchBoxByType,
    GlSprintf,
    GlIcon,
    GlLoadingIcon,
    RefResultsSection,
  },
  props: {
    value: {
      type: String,
      required: false,
      default: '',
    },
    projectId: {
      type: String,
      required: true,
    },
    translations: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      query: '',
    };
  },
  computed: {
    ...mapState({
      matches: state => state.matches,
      lastQuery: state => state.query,
      selectedRef: state => state.selectedRef,
    }),
    ...mapGetters(['isLoading', 'isQueryPossiblyASha']),
    i18n() {
      return {
        ...DEFAULT_I18N,
        ...this.translations,
      };
    },
    showBranchesSection() {
      return Boolean(this.matches.branches.totalCount > 0 || this.matches.branches.error);
    },
    showTagsSection() {
      return Boolean(this.matches.tags.totalCount > 0 || this.matches.tags.error);
    },
    showCommitsSection() {
      return Boolean(this.matches.commits.totalCount > 0 || this.matches.commits.error);
    },
    showNoResults() {
      return !this.showBranchesSection && !this.showTagsSection && !this.showCommitsSection;
    },
  },
  watch: {
    // Keep the Vuex store synchronized if the parent
    // component updates the selected ref through v-model
    value: {
      immediate: true,
      handler() {
        if (this.value !== this.selectedRef) {
          this.setSelectedRef(this.value);
        }
      },
    },
  },
  created() {
    // This method is defined here instead of in `methods`
    // because we need to access the .cancel() method
    // lodash attaches to the function, which is
    // made inaccessible by Vue. More info:
    // https://stackoverflow.com/a/52988020/1063392
    this.debouncedSearch = debounce(function search() {
      this.search(this.query);
    }, SEARCH_DEBOUNCE_MS);

    this.setProjectId(this.projectId);
    this.search(this.query);
  },
  methods: {
    ...mapActions(['setProjectId', 'setSelectedRef', 'search']),
    focusSearchBox() {
      this.$refs.searchBox.$el.querySelector('input').focus();
    },
    onSearchBoxEnter() {
      this.debouncedSearch.cancel();
      this.search(this.query);
    },
    onSearchBoxInput() {
      this.debouncedSearch();
    },
    selectRef(ref) {
      this.setSelectedRef(ref);
      this.$emit('input', this.selectedRef);
    },
  },
};
</script>

<template>
  <gl-dropdown v-bind="$attrs" class="ref-selector" @shown="focusSearchBox">
    <template slot="button-content">
      <span class="gl-flex-grow-1 gl-ml-2 gl-text-gray-400" data-testid="button-content">
        <span v-if="selectedRef" class="gl-font-monospace">{{ selectedRef }}</span>
        <span v-else>{{ i18n.noRefSelected }}</span>
      </span>
      <gl-icon name="chevron-down" />
    </template>

    <div class="gl-display-flex gl-flex-direction-column ref-selector-dropdown-content">
      <gl-dropdown-section-header>
        <span class="gl-text-center gl-display-block">{{ i18n.dropdownHeader }}</span>
      </gl-dropdown-section-header>

      <gl-dropdown-divider />

      <gl-search-box-by-type
        ref="searchBox"
        v-model.trim="query"
        :placeholder="i18n.searchPlaceholder"
        @input="onSearchBoxInput"
        @keydown.enter.prevent="onSearchBoxEnter"
      />

      <div class="gl-flex-grow-1 gl-overflow-y-auto">
        <gl-loading-icon v-if="isLoading" size="lg" class="gl-my-3" />

        <div
          v-else-if="showNoResults"
          class="gl-text-center gl-mx-3 gl-py-3"
          data-testid="no-results"
        >
          <gl-sprintf v-if="lastQuery" :message="i18n.noResultsWithQuery">
            <template #query>
              <b class="gl-word-break-all">{{ lastQuery }}</b>
            </template>
          </gl-sprintf>

          <span v-else>{{ i18n.noResults }}</span>
        </div>

        <template v-else>
          <template v-if="showBranchesSection">
            <ref-results-section
              :section-title="i18n.branches"
              :total-count="matches.branches.totalCount"
              :items="matches.branches.list"
              :selected-ref="selectedRef"
              :error="matches.branches.error"
              :error-message="i18n.branchesErrorMessage"
              data-testid="branches-section"
              @selected="selectRef($event)"
            />

            <gl-dropdown-divider v-if="showTagsSection || showCommitsSection" />
          </template>

          <template v-if="showTagsSection">
            <ref-results-section
              :section-title="i18n.tags"
              :total-count="matches.tags.totalCount"
              :items="matches.tags.list"
              :selected-ref="selectedRef"
              :error="matches.tags.error"
              :error-message="i18n.tagsErrorMessage"
              data-testid="tags-section"
              @selected="selectRef($event)"
            />

            <gl-dropdown-divider v-if="showCommitsSection" />
          </template>

          <template v-if="showCommitsSection">
            <ref-results-section
              :section-title="i18n.commits"
              :total-count="matches.commits.totalCount"
              :items="matches.commits.list"
              :selected-ref="selectedRef"
              :error="matches.commits.error"
              :error-message="i18n.commitsErrorMessage"
              data-testid="commits-section"
              @selected="selectRef($event)"
            />
          </template>
        </template>
      </div>
    </div>
  </gl-dropdown>
</template>
