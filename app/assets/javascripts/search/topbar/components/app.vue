<script>
import { GlButton } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions, mapGetters } from 'vuex';
import { InternalEvents } from '~/tracking';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { s__ } from '~/locale';
import MarkdownDrawer from '~/vue_shared/components/markdown_drawer/markdown_drawer.vue';
import {
  ZOEKT_SEARCH_TYPE,
  ADVANCED_SEARCH_TYPE,
  REGEX_PARAM,
  LS_REGEX_HANDLE,
} from '~/search/store/constants';
import { loadDataFromLS } from '~/search/store/utils';
import { SCOPE_BLOB } from '~/search/sidebar/constants';
import { SYNTAX_OPTIONS_ADVANCED_DOCUMENT, SYNTAX_OPTIONS_ZOEKT_DOCUMENT } from '../constants';

import SearchTypeIndicator from './search_type_indicator.vue';
import GlSearchBoxByType from './search_box_by_type.vue';

const trackingMixin = InternalEvents.mixin();

export default {
  name: 'GlobalSearchTopbar',
  i18n: {
    searchPlaceholder: s__(`GlobalSearch|Search for projects, issues, etc.`),
    searchLabel: s__(`GlobalSearch|What are you searching for?`),
    syntaxOptionsLabel: s__('GlobalSearch|View syntax options.'),
    groupFieldLabel: s__('GlobalSearch|Group'),
    projectFieldLabel: s__('GlobalSearch|Project'),
  },
  components: {
    GlButton,
    GlSearchBoxByType,
    MarkdownDrawer,
    SearchTypeIndicator,
  },
  mixins: [glFeatureFlagsMixin(), trackingMixin],
  data() {
    return {
      regexEnabled: false,
    };
  },
  computed: {
    ...mapState(['query', 'searchType', 'defaultBranchName', 'urlQuery']),
    ...mapGetters(['currentScope']),
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
    isRegexButtonVisible() {
      return this.searchType === ZOEKT_SEARCH_TYPE && this.isDefaultBranch;
    },
    isMultiMatch() {
      return (
        this.glFeatures.zoektMultimatchFrontend &&
        this.searchType === ZOEKT_SEARCH_TYPE &&
        this.currentScope === SCOPE_BLOB
      );
    },
  },
  created() {
    this.preloadStoredFrequentItems();
    this.regexEnabled = loadDataFromLS(LS_REGEX_HANDLE);
  },
  methods: {
    ...mapActions(['applyQuery', 'setQuery', 'preloadStoredFrequentItems']),
    onToggleDrawer() {
      this.$refs.markdownDrawer.toggleDrawer();
    },
    regexButtonHandler() {
      this.addReguralExpressionToQuery();
      this.trackEvent('click_regex_button_in_search_page_input');
    },
    addReguralExpressionToQuery(value = !this.regexEnabled) {
      this.setQuery({ key: REGEX_PARAM, value });
      this.regexEnabled = value;
      if (this.search) {
        this.applyQuery();
      }
    },
    submitSearch() {
      if (!this.isMultiMatch) {
        this.applyQuery();
      }
    },
  },
};
</script>

<template>
  <section>
    <div class="search-page-form gl-mt-5">
      <search-type-indicator />
      <template v-if="showSyntaxOptions">
        <div class="gl-inline-block">
          <gl-button category="tertiary" variant="link" @click="onToggleDrawer"
            >{{ $options.i18n.syntaxOptionsLabel }}
          </gl-button>
        </div>
        <markdown-drawer ref="markdownDrawer" :document-path="documentBasedOnSearchType" />
      </template>
      <gl-search-box-by-type
        id="dashboard_search"
        v-model="search"
        name="search"
        class="gl-mt-2"
        :regex-button-is-visible="isRegexButtonVisible"
        :regex-button-state="regexEnabled"
        :regex-button-handler="regexButtonHandler"
        :placeholder="$options.i18n.searchPlaceholder"
        @keydown.enter.stop.prevent="submitSearch"
      />
    </div>
  </section>
</template>
