<script>
import { GlSearchBoxByClick, GlButton } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { s__ } from '~/locale';
import { parseBoolean } from '~/lib/utils/common_utils';
import MarkdownDrawer from '~/vue_shared/components/markdown_drawer/markdown_drawer.vue';
import { SYNTAX_OPTIONS_DOCUMENT } from '../constants';
import GroupFilter from './group_filter.vue';
import ProjectFilter from './project_filter.vue';

export default {
  name: 'GlobalSearchTopbar',
  i18n: {
    searchPlaceholder: s__(`GlobalSearch|Search for projects, issues, etc.`),
    searchLabel: s__(`GlobalSearch|What are you searching for?`),
    documentFetchErrorMessage: s__(
      'GlobalSearch|There was an error fetching the "Syntax Options" document.',
    ),
    searchFieldLabel: s__('GlobalSearch|What are you searching for?'),
    syntaxOptionsLabel: s__('GlobalSearch|Syntax options'),
    groupFieldLabel: s__('GlobalSearch|Group'),
    projectFieldLabel: s__('GlobalSearch|Project'),
    searchButtonLabel: s__('GlobalSearch|Search'),
    closeButtonLabel: s__('GlobalSearch|Close'),
  },
  components: {
    GlButton,
    GlSearchBoxByClick,
    GroupFilter,
    ProjectFilter,
    MarkdownDrawer,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    groupInitialJson: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    projectInitialJson: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    elasticsearchEnabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    defaultBranchName: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    ...mapState(['query']),
    search: {
      get() {
        return this.query ? this.query.search : '';
      },
      set(value) {
        this.setQuery({ key: 'search', value });
      },
    },
    showFilters() {
      return !parseBoolean(this.query.snippets);
    },
    showSyntaxOptions() {
      return this.elasticsearchEnabled && this.isDefaultBranch;
    },
    hasVerticalNav() {
      return this.glFeatures.searchPageVerticalNav;
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
  SYNTAX_OPTIONS_DOCUMENT,
};
</script>

<template>
  <section class="search-page-form gl-lg-display-flex gl-flex-direction-column">
    <div class="gl-lg-display-flex gl-flex-direction-row gl-align-items-flex-end">
      <div class="gl-flex-grow-1 gl-mb-4 gl-lg-mb-0 gl-lg-mr-2">
        <div
          class="gl-sm-display-flex gl-flex-direction-row gl-justify-content-space-between gl-mb-4 gl-md-mb-0"
        >
          <label>{{ $options.i18n.searchLabel }}</label>
          <template v-if="showSyntaxOptions">
            <gl-button
              category="tertiary"
              variant="link"
              size="small"
              button-text-classes="gl-font-sm!"
              @click="onToggleDrawer"
              >{{ $options.i18n.syntaxOptionsLabel }}
            </gl-button>
            <markdown-drawer
              ref="markdownDrawer"
              :document-path="$options.SYNTAX_OPTIONS_DOCUMENT"
            />
          </template>
        </div>
        <gl-search-box-by-click
          id="dashboard_search"
          v-model="search"
          name="search"
          :placeholder="$options.i18n.searchPlaceholder"
          @submit="applyQuery"
        />
      </div>
      <div v-if="showFilters" class="gl-mb-4 gl-lg-mb-0 gl-lg-mx-3">
        <label class="gl-display-block">{{ $options.i18n.groupFieldLabel }}</label>
        <group-filter :initial-data="groupInitialJson" />
      </div>
      <div v-if="showFilters" class="gl-mb-4 gl-lg-mb-0 gl-lg-ml-3">
        <label class="gl-display-block">{{ $options.i18n.projectFieldLabel }}</label>
        <project-filter :initial-data="projectInitialJson" />
      </div>
    </div>
    <hr v-if="hasVerticalNav" class="gl-mt-5 gl-mb-0 gl-border-gray-100" />
  </section>
</template>
