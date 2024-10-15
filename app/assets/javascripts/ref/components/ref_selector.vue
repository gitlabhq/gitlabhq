<script>
import { GlBadge, GlIcon, GlCollapsibleListbox } from '@gitlab/ui';
import { debounce, isArray } from 'lodash';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapGetters, mapState } from 'vuex';
import { sprintf } from '~/locale';
import ProtectedBadge from '~/vue_shared/components/badges/protected_badge.vue';
import {
  ALL_REF_TYPES,
  SEARCH_DEBOUNCE_MS,
  DEFAULT_I18N,
  REF_TYPE_BRANCHES,
  REF_TYPE_TAGS,
  REF_TYPE_COMMITS,
  TAG_REF_TYPE,
  BRANCH_REF_TYPE,
  TAG_REF_TYPE_ICON,
  BRANCH_REF_TYPE_ICON,
} from '../constants';
import createStore from '../stores';
import { formatListBoxItems, formatErrors } from '../format_refs';

export default {
  name: 'RefSelector',
  components: {
    GlBadge,
    GlIcon,
    GlCollapsibleListbox,
    ProtectedBadge,
  },
  inheritAttrs: false,
  props: {
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    enabledRefTypes: {
      type: Array,
      required: false,
      default: () => ALL_REF_TYPES,
      validator: (val) =>
        // It has to be an array
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
    queryParams: {
      type: Object,
      required: false,
      default: () => {},
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
    toggleButtonClass: {
      type: [String, Object, Array],
      required: false,
      default: null,
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
      params: (state) => state.params,
    }),
    ...mapGetters(['isLoading', 'isQueryPossiblyASha']),
    i18n() {
      return {
        ...DEFAULT_I18N,
        ...this.translations,
      };
    },
    listBoxItems() {
      return formatListBoxItems(this.branches, this.tags, this.commits);
    },
    branches() {
      return this.enabledRefTypes.includes(REF_TYPE_BRANCHES) ? this.matches.branches.list : [];
    },
    tags() {
      return this.enabledRefTypes.includes(REF_TYPE_TAGS) ? this.matches.tags.list : [];
    },
    commits() {
      return this.enabledRefTypes.includes(REF_TYPE_COMMITS) ? this.matches.commits.list : [];
    },
    extendedToggleButtonClass() {
      const classes = [
        {
          '!gl-shadow-inner-1-red-500': !this.state,
          'gl-font-monospace': Boolean(this.selectedRef),
        },
        'gl-mb-0',
      ];

      if (Array.isArray(this.toggleButtonClass)) {
        classes.push(...this.toggleButtonClass);
      } else {
        classes.push(this.toggleButtonClass);
      }

      return classes;
    },
    footerSlotProps() {
      return {
        isLoading: this.isLoading,
        matches: this.matches,
        query: this.lastQuery,
      };
    },
    errors() {
      return formatErrors(this.matches.branches, this.matches.tags, this.matches.commits);
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
    noResultsMessage() {
      return this.lastQuery
        ? sprintf(this.i18n.noResultsWithQuery, {
            query: this.lastQuery,
          })
        : this.i18n.noResults;
    },
    dropdownIcon() {
      let icon;

      if (this.selectedRef.includes(`refs/${TAG_REF_TYPE}`)) {
        icon = TAG_REF_TYPE_ICON;
      } else if (this.selectedRef.includes(`refs/${BRANCH_REF_TYPE}`)) {
        icon = BRANCH_REF_TYPE_ICON;
      }

      return icon;
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
    this.debouncedSearch = debounce(this.search, SEARCH_DEBOUNCE_MS);

    this.setProjectId(this.projectId);
    this.setParams(this.queryParams);

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
      'setParams',
      'setProjectId',
      'setSelectedRef',
    ]),
    ...mapActions({ storeSearch: 'search' }),
    onSearchBoxInput(searchQuery = '') {
      this.query = searchQuery?.trim();
      this.debouncedSearch();
    },
    selectRef(ref) {
      if (this.disabled) {
        return;
      }

      this.setSelectedRef(ref);
      this.$emit('input', this.selectedRef);
    },
    search() {
      this.storeSearch(this.query);
    },
    totalCountText(count) {
      return count > 999 ? this.i18n.totalCountLabel : `${count}`;
    },
  },
};
</script>

<template>
  <div>
    <gl-collapsible-listbox
      class="ref-selector gl-w-full"
      block
      searchable
      :selected="selectedRef"
      :header-text="i18n.dropdownHeader"
      :items="listBoxItems"
      :no-results-text="noResultsMessage"
      :searching="isLoading"
      :search-placeholder="i18n.searchPlaceholder"
      :toggle-class="extendedToggleButtonClass"
      :toggle-text="buttonText"
      :icon="dropdownIcon"
      :disabled="disabled"
      v-bind="$attrs"
      v-on="$listeners"
      @hidden="$emit('hide')"
      @search="onSearchBoxInput"
      @select="selectRef"
    >
      <template #group-label="{ group }">
        {{ group.text }} <gl-badge>{{ totalCountText(group.options.length) }}</gl-badge>
      </template>
      <template #list-item="{ item }">
        {{ item.text }}
        <gl-badge v-if="item.default" variant="info">{{ i18n.defaultLabelText }}</gl-badge>
        <protected-badge v-if="item.protected" />
      </template>
      <template #footer>
        <slot name="footer" v-bind="footerSlotProps"></slot>
        <div
          v-for="errorMessage in errors"
          :key="errorMessage"
          data-testid="red-selector-error-list"
          class="gl-mx-4 gl-my-3 gl-flex gl-items-start gl-text-red-500"
        >
          <gl-icon name="error" class="gl-mr-2 gl-mt-2 gl-shrink-0" />
          <span>{{ errorMessage }}</span>
        </div>
      </template>
    </gl-collapsible-listbox>
    <input
      v-if="name"
      data-testid="selected-ref-form-field"
      type="hidden"
      :value="selectedRef"
      :name="name"
    />
  </div>
</template>
