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
  BRANCH_REF_TYPE,
  TAG_REF_TYPE,
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
  inheritAttrs: false,
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
    refType: {
      type: String,
      required: false,
      default: null,
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
    useSymbolicRefNames: {
      type: Boolean,
      required: false,
      default: false,
    },

    /** The validation state of this component. */
    state: {
      type: Boolean,
      required: false,
      default: true,
    },

    /* Underlying form field name for scenarios where ref_selector
     * is used as part of submitting an HTML form
     */
    name: {
      type: String,
      required: false,
      default: '',
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
    selectedRefForDisplay() {
      if (this.useSymbolicRefNames && this.selectedRef) {
        return this.selectedRef.replace(/^refs\/(tags|heads)\//, '');
      }

      return this.selectedRef;
    },
    buttonText() {
      return this.selectedRefForDisplay || this.i18n.noRefSelected;
    },
    isTagRefType() {
      return this.refType === TAG_REF_TYPE;
    },
    isBranchRefType() {
      return this.refType === BRANCH_REF_TYPE;
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
    // made inaccessible by Vue.
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

    this.$watch(
      'useSymbolicRefNames',
      () => this.setUseSymbolicRefNames(this.useSymbolicRefNames),
      { immediate: true },
    );
  },
  methods: {
    ...mapActions([
      'setEnabledRefTypes',
      'setUseSymbolicRefNames',
      'setProjectId',
      'setSelectedRef',
    ]),
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
  <div>
    <gl-dropdown
      :header-text="i18n.dropdownHeader"
      :toggle-class="toggleButtonClass"
      :text="buttonText"
      class="ref-selector gl-w-full"
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
          data-qa-selector="ref_selector_searchbox"
          @input="onSearchBoxInput"
          @keydown.enter.prevent="onSearchBoxEnter"
        />
      </template>

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
            :show-header="showSectionHeaders"
            data-testid="branches-section"
            data-qa-selector="branches_section"
            :should-show-check="!useSymbolicRefNames || isBranchRefType"
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
            :should-show-check="!useSymbolicRefNames || isTagRefType"
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
    <input
      v-if="name"
      data-testid="selected-ref-form-field"
      type="hidden"
      :value="selectedRef"
      :name="name"
    />
  </div>
</template>
