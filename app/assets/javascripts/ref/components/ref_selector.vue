<script>
import {
  GlDropdown,
  GlDropdownDivider,
  GlSearchBoxByType,
  GlSprintf,
  GlLoadingIcon,
} from '@gitlab/ui';
import { debounce, isArray } from 'lodash';
import { mapActions, mapGetters, mapState } from 'vuex';
import {
  ALL_REF_TYPES,
  SEARCH_DEBOUNCE_MS,
  DEFAULT_I18N,
  REF_TYPE_BRANCHES,
  REF_TYPE_TAGS,
  REF_TYPE_COMMITS,
} from '../constants';
import createStore from '../stores';
import RefResultsSection from './ref_results_section.vue';

export default {
  name: 'RefSelector',
  components: {
    GlDropdown,
    GlDropdownDivider,
    GlSearchBoxByType,
    GlSprintf,
    GlLoadingIcon,
    RefResultsSection,
  },
  props: {
    enabledRefTypes: {
      type: Array,
      required: false,
      default: () => ALL_REF_TYPES,
      validator: (val) =>
        // It has to be an arrray
        isArray(val) &&
        // with at least one item
        val.length > 0 &&
        // and only "REF_TYPE_BRANCHES", "REF_TYPE_TAGS", and "REF_TYPE_COMMITS" are allowed
        val.every((item) => ALL_REF_TYPES.includes(item)) &&
        // and no duplicates are allowed
        val.length === new Set(val).size,
    },
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

    /** The validation state of this component. */
    state: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  data() {
    return {
      query: '',
    };
  },
  computed: {
    ...mapState({
      matches: (state) => state.matches,
      lastQuery: (state) => state.query,
      selectedRef: (state) => state.selectedRef,
    }),
    ...mapGetters(['isLoading', 'isQueryPossiblyASha']),
    i18n() {
      return {
        ...DEFAULT_I18N,
        ...this.translations,
      };
    },
    showBranchesSection() {
      return (
        this.enabledRefTypes.includes(REF_TYPE_BRANCHES) &&
        Boolean(this.matches.branches.totalCount > 0 || this.matches.branches.error)
      );
    },
    showTagsSection() {
      return (
        this.enabledRefTypes.includes(REF_TYPE_TAGS) &&
        Boolean(this.matches.tags.totalCount > 0 || this.matches.tags.error)
      );
    },
    showCommitsSection() {
      return (
        this.enabledRefTypes.includes(REF_TYPE_COMMITS) &&
        Boolean(this.matches.commits.totalCount > 0 || this.matches.commits.error)
      );
    },
    showNoResults() {
      return !this.showBranchesSection && !this.showTagsSection && !this.showCommitsSection;
    },
    showSectionHeaders() {
      return this.enabledRefTypes.length > 1;
    },
    toggleButtonClass() {
      return {
        'gl-inset-border-1-red-500!': !this.state,
        'gl-font-monospace': Boolean(this.selectedRef),
      };
    },
    footerSlotProps() {
      return {
        isLoading: this.isLoading,
        matches: this.matches,
        query: this.lastQuery,
      };
    },
    buttonText() {
      return this.selectedRef || this.i18n.noRefSelected;
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
  beforeCreate() {
    // Setting the store here instead of using
    // the built in `store` component option because
    // we need each new `RefSelector` instance to
    // create a new Vuex store instance.
    // See https://github.com/vuejs/vuex/issues/414#issue-184491718.
    this.$store = createStore();
  },
  created() {
    // This method is defined here instead of in `methods`
    // because we need to access the .cancel() method
    // lodash attaches to the function, which is
    // made inaccessible by Vue. More info:
    // https://stackoverflow.com/a/52988020/1063392
    this.debouncedSearch = debounce(function search() {
      this.search();
    }, SEARCH_DEBOUNCE_MS);

    this.setProjectId(this.projectId);

    this.$watch(
      'enabledRefTypes',
      () => {
        this.setEnabledRefTypes(this.enabledRefTypes);
        this.search();
      },
      { immediate: true },
    );
  },
  methods: {
    ...mapActions(['setEnabledRefTypes', 'setProjectId', 'setSelectedRef']),
    ...mapActions({ storeSearch: 'search' }),
    focusSearchBox() {
      this.$refs.searchBox.$el.querySelector('input').focus();
    },
    onSearchBoxEnter() {
      this.debouncedSearch.cancel();
      this.search();
    },
    onSearchBoxInput() {
      this.debouncedSearch();
    },
    selectRef(ref) {
      this.setSelectedRef(ref);
      this.$emit('input', this.selectedRef);
    },
    search() {
      this.storeSearch(this.query);
    },
  },
};
</script>

<template>
  <gl-dropdown
    :header-text="i18n.dropdownHeader"
    :toggle-class="toggleButtonClass"
    :text="buttonText"
    class="ref-selector"
    v-bind="$attrs"
    v-on="$listeners"
    @shown="focusSearchBox"
  >
    <template #header>
      <gl-search-box-by-type
        ref="searchBox"
        v-model.trim="query"
        :placeholder="i18n.searchPlaceholder"
        autocomplete="off"
        @input="onSearchBoxInput"
        @keydown.enter.prevent="onSearchBoxEnter"
      />
    </template>

    <gl-loading-icon v-if="isLoading" size="lg" class="gl-my-3" />

    <div v-else-if="showNoResults" class="gl-text-center gl-mx-3 gl-py-3" data-testid="no-results">
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
          :show-header="showSectionHeaders"
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
          :show-header="showSectionHeaders"
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
          :show-header="showSectionHeaders"
          data-testid="commits-section"
          @selected="selectRef($event)"
        />
      </template>
    </template>

    <template #footer>
      <slot name="footer" v-bind="footerSlotProps"></slot>
    </template>
  </gl-dropdown>
</template>
