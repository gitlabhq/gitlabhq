<script>
import { GlSearchBoxByType, GlButton } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions } from 'vuex';
import { s__ } from '~/locale';
import MarkdownDrawer from '~/vue_shared/components/markdown_drawer/markdown_drawer.vue';
import { ZOEKT_SEARCH_TYPE, ADVANCED_SEARCH_TYPE } from '~/search/store/constants';
import { SYNTAX_OPTIONS_ADVANCED_DOCUMENT, SYNTAX_OPTIONS_ZOEKT_DOCUMENT } from '../constants';
import SearchTypeIndicator from './search_type_indicator.vue';

export default {
  name: 'GlobalSearchTopbar',
  i18n: {
    searchPlaceholder: s__(`GlobalSearch|Search for projects, issues, etc.`),
    searchLabel: s__(`GlobalSearch|What are you searching for?`),
    syntaxOptionsLabel: s__('GlobalSearch|Syntax options'),
    groupFieldLabel: s__('GlobalSearch|Group'),
    projectFieldLabel: s__('GlobalSearch|Project'),
  },
  components: {
    GlButton,
    GlSearchBoxByType,
    MarkdownDrawer,
    SearchTypeIndicator,
  },
  props: {
    defaultBranchName: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    ...mapState(['query', 'searchType']),
    search: {
      get() {
        return this.query ? this.query.search : '';
      },
      set(value) {
        this.setQuery({ key: 'search', value });
      },
    },
    showSyntaxOptions() {
      return (
        (this.searchType === ZOEKT_SEARCH_TYPE || this.searchType === ADVANCED_SEARCH_TYPE) &&
        this.isDefaultBranch
      );
    },
    documentBasedOnSearchType() {
      return this.searchType === ZOEKT_SEARCH_TYPE
        ? SYNTAX_OPTIONS_ZOEKT_DOCUMENT
        : SYNTAX_OPTIONS_ADVANCED_DOCUMENT;
    },
    isDefaultBranch() {
      return !this.query.repository_ref || this.query.repository_ref === this.defaultBranchName;
    },
  },
  created() {
    this.preloadStoredFrequentItems();
  },
  methods: {
    ...mapActions(['applyQuery', 'setQuery', 'preloadStoredFrequentItems']),
    onToggleDrawer() {
      this.$refs.markdownDrawer.toggleDrawer();
    },
  },
};
</script>

<template>
  <section>
    <div
      class="gl-lg-display-flex gl-flex-direction-row gl-py-5"
      :class="{
        'gl-justify-content-space-between': showSyntaxOptions,
        'gl-justify-content-end': !showSyntaxOptions,
      }"
    >
      <template v-if="showSyntaxOptions">
        <div>
          <gl-button
            category="tertiary"
            variant="link"
            size="small"
            button-text-classes="gl-font-sm!"
            @click="onToggleDrawer"
            >{{ $options.i18n.syntaxOptionsLabel }}
          </gl-button>
        </div>
        <markdown-drawer ref="markdownDrawer" :document-path="documentBasedOnSearchType" />
      </template>
      <search-type-indicator />
    </div>
    <div class="search-page-form gl-lg-display-flex gl-flex-direction-column">
      <div class="gl-lg-display-flex gl-flex-direction-row gl-align-items-flex-start">
        <div class="gl-flex-grow-1 gl-pb-8 gl-lg-mb-0 gl-lg-mr-2">
          <gl-search-box-by-type
            id="dashboard_search"
            v-model="search"
            name="search"
            :placeholder="$options.i18n.searchPlaceholder"
            @keydown.enter.stop.prevent="applyQuery"
          />
        </div>
      </div>
    </div>
  </section>
</template>
