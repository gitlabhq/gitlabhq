<script>
import {
  GlBadge,
  GlButton,
  GlButtonGroup,
  GlEmptyState,
  GlIcon,
  GlLoadingIcon,
  GlSearchBoxByType,
  GlSorting,
  GlTab,
  GlTabs,
} from '@gitlab/ui';
import EMPTY_SVG_URL from '@gitlab/svgs/dist/illustrations/empty-state/empty-catalog-md.svg?url';
import FILTERED_SVG_URL from '@gitlab/svgs/dist/illustrations/empty-state/empty-search-md.svg?url';
import { s__ } from '~/locale';
import {
  SORT_OPTION_POPULARITY,
  SORT_OPTION_RELEASED,
  SORT_OPTION_STAR_COUNT,
  VERIFICATION_LEVEL_UNVERIFIED,
} from '~/ci/catalog/constants';
import getCatalogResources from '~/ci/catalog/graphql/queries/get_ci_catalog_resources.query.graphql';
import getCiCatalogBundledResources from '~/ci/catalog/graphql/queries/get_ci_catalog_bundled_resources.query.graphql';
import CatalogHeader from '../list/catalog_header.vue';
import CiResourcesListItem from '../list/ci_resources_list_item.vue';

const SORT_OPTION_NAME = 'NAME';

const SORT_COMPARATORS = {
  [SORT_OPTION_NAME]: (a, b) => a.name.localeCompare(b.name),
  [SORT_OPTION_RELEASED]: (a, b) =>
    new Date(a.versions.nodes[0]?.releasedAt) - new Date(b.versions.nodes[0]?.releasedAt),
  [SORT_OPTION_POPULARITY]: (a, b) => a.last30DayUsageCount - b.last30DayUsageCount,
  [SORT_OPTION_STAR_COUNT]: (a, b) => a.starCount - b.starCount,
};

const DEMO_STATE_POPULATED = 'populated';
const DEMO_STATE_EMPTY_ORG = 'emptyOrg';
const DEMO_STATE_EMPTY_BUNDLED = 'emptyBundled';

const ORG_SORT_ITEMS = [
  { value: SORT_OPTION_POPULARITY, text: s__('CiCatalog|Usage') },
  { value: SORT_OPTION_RELEASED, text: s__('CiCatalog|Last released') },
  { value: SORT_OPTION_STAR_COUNT, text: s__('CiCatalog|Stars') },
  { value: SORT_OPTION_NAME, text: s__('CiCatalog|Name') },
];

const BUNDLED_SORT_ITEMS = [
  { value: SORT_OPTION_RELEASED, text: s__('CiCatalog|Last released') },
  { value: SORT_OPTION_NAME, text: s__('CiCatalog|Name') },
];

// Bundled resources come from `ciCatalogBundledResources`, which returns a leaner
// shape than an org `CiCatalogResource`. Map it into the shape CiResourcesListItem
// expects. Stats/author are hidden for the bundled tab, so those fields are stubbed.
const adaptBundledResource = (node) => ({
  id: node.id,
  name: node.name,
  description: node.description,
  fullPath: node.fullPath,
  webPath: node.fullPath,
  serverFqdn: node.serverFqdn,
  // Bundled resources have no per-record verification level (the "GitLab-maintained"
  // signal is the tab + callout); UNVERIFIED suppresses the per-card badge.
  verificationLevel: VERIFICATION_LEVEL_UNVERIFIED,
  starCount: 0,
  last30DayUsageCount: 0,
  topics: [],
  icon: null,
  archived: false,
  versions: {
    nodes: node.latestReleasedAt
      ? [
          {
            name: node.latestVersionName,
            path: `/${node.fullPath}`,
            releasedAt: node.latestReleasedAt,
            author: null,
          },
        ]
      : [],
  },
});

export default {
  name: 'TwoSourceBrowse',
  components: {
    CatalogHeader,
    CiResourcesListItem,
    GlBadge,
    GlButton,
    GlButtonGroup,
    GlEmptyState,
    GlIcon,
    GlLoadingIcon,
    GlSearchBoxByType,
    GlSorting,
    GlTab,
    GlTabs,
  },
  data() {
    return {
      orgResources: [],
      bundledResources: [],
      activeTabIndex: 0,
      searchTerm: '',
      orgSort: SORT_OPTION_POPULARITY,
      bundledSort: SORT_OPTION_RELEASED,
      isAscending: false,
      demoState: DEMO_STATE_POPULATED,
    };
  },
  apollo: {
    orgResources: {
      query: getCatalogResources,
      variables() {
        return { first: 20 };
      },
      update(data) {
        return data?.ciCatalogResources?.nodes || [];
      },
      error() {
        this.orgResources = [];
      },
    },
    bundledResources: {
      query: getCiCatalogBundledResources,
      variables() {
        return { first: 20 };
      },
      update(data) {
        return (data?.ciCatalogBundledResources?.nodes || []).map(adaptBundledResource);
      },
      error() {
        this.bundledResources = [];
      },
    },
  },
  computed: {
    isLoading() {
      return this.isBundledTab
        ? this.$apollo.queries.bundledResources.loading
        : this.$apollo.queries.orgResources.loading;
    },
    isBundledTab() {
      return this.activeTabIndex === 1;
    },
    effectiveOrgResources() {
      return this.demoState === DEMO_STATE_EMPTY_ORG ? [] : this.orgResources;
    },
    effectiveBundledResources() {
      return this.demoState === DEMO_STATE_EMPTY_BUNDLED ? [] : this.bundledResources;
    },
    sortItems() {
      return this.isBundledTab ? BUNDLED_SORT_ITEMS : ORG_SORT_ITEMS;
    },
    selectedSort() {
      return this.isBundledTab ? this.bundledSort : this.orgSort;
    },
    selectedSortText() {
      return this.sortItems.find((item) => item.value === this.selectedSort)?.text;
    },
    sourceResources() {
      return this.isBundledTab ? this.effectiveBundledResources : this.effectiveOrgResources;
    },
    filteredResources() {
      const term = this.searchTerm.trim().toLowerCase();
      const matched = term
        ? this.sourceResources.filter((resource) => resource.name.toLowerCase().includes(term))
        : [...this.sourceResources];

      const comparator = SORT_COMPARATORS[this.selectedSort];
      if (!comparator) {
        return matched;
      }

      const direction = this.isAscending ? 1 : -1;
      return matched.sort((a, b) => direction * comparator(a, b));
    },
    isSearching() {
      return this.searchTerm.trim().length > 0;
    },
    showEmptyState() {
      return !this.isLoading && this.filteredResources.length === 0;
    },
    emptyStateLabels() {
      if (this.isSearching) {
        return this.$options.i18n.searchEmpty;
      }
      return this.isBundledTab ? this.$options.i18n.bundledEmpty : this.$options.i18n.orgEmpty;
    },
  },
  methods: {
    onTabChange(index) {
      this.activeTabIndex = index;
      this.searchTerm = '';
    },
    onSortSelect(value) {
      if (this.isBundledTab) {
        this.bundledSort = value;
      } else {
        this.orgSort = value;
      }
    },
    onSortDirectionToggle() {
      this.isAscending = !this.isAscending;
    },
    setDemoState(value) {
      this.demoState = value;
      this.searchTerm = '';
    },
  },
  demoStates: [
    { value: DEMO_STATE_POPULATED, text: s__('CiCatalog|Populated') },
    { value: DEMO_STATE_EMPTY_ORG, text: s__('CiCatalog|Empty: your organization') },
    { value: DEMO_STATE_EMPTY_BUNDLED, text: s__('CiCatalog|Empty: GitLab-maintained') },
  ],
  EMPTY_SVG_URL,
  FILTERED_SVG_URL,
  i18n: {
    orgEmpty: {
      title: s__('CiCatalog|Get started with the CI/CD Catalog'),
      description: s__(
        'CiCatalog|Create a pipeline component repository and make reusing pipeline configurations faster and easier.',
      ),
    },
    bundledEmpty: {
      title: s__('CiCatalog|No GitLab-maintained components yet'),
      description: s__(
        'CiCatalog|GitLab-maintained components have not been made available on this cell yet. They will appear here once they are synced.',
      ),
    },
    searchEmpty: {
      title: s__('CiCatalog|No components match your search criteria'),
      description: s__('CiCatalog|Edit your search and try again.'),
    },
  },
};
</script>

<template>
  <div class="@container/panel">
    <div
      class="gl-border-warning gl-mb-4 gl-flex gl-flex-wrap gl-items-center gl-gap-3 gl-rounded-base gl-border-1 gl-border-dashed gl-bg-feedback-warning gl-p-3 gl-text-sm"
      data-testid="cells-demo-controls"
    >
      <span class="gl-font-bold gl-text-subtle">🔧 {{ s__('CiCatalog|Preview state:') }}</span>
      <gl-button-group>
        <gl-button
          v-for="state in $options.demoStates"
          :key="state.value"
          size="small"
          :selected="demoState === state.value"
          :category="demoState === state.value ? 'primary' : 'secondary'"
          @click="setDemoState(state.value)"
        >
          {{ state.text }}
        </gl-button>
      </gl-button-group>
    </div>

    <catalog-header />

    <gl-tabs content-class="gl-py-0" @input="onTabChange">
      <gl-tab>
        <template #title>
          <span>{{ s__('CiCatalog|Your organization') }}</span>
          <gl-badge class="gl-tab-counter-badge">{{ effectiveOrgResources.length }}</gl-badge>
        </template>
      </gl-tab>
      <gl-tab>
        <template #title>
          <gl-icon name="tanuki-verified" class="gl-mr-2 gl-text-blue-500" />
          <span>{{ s__('CiCatalog|GitLab-maintained') }}</span>
          <gl-badge class="gl-tab-counter-badge">{{ effectiveBundledResources.length }}</gl-badge>
        </template>
      </gl-tab>
    </gl-tabs>

    <div
      v-if="isBundledTab"
      class="gl-mt-4 gl-flex gl-items-start gl-gap-3 gl-rounded-base gl-bg-feedback-info gl-p-4 gl-text-sm gl-text-subtle"
      data-testid="bundled-callout"
    >
      <gl-icon name="tanuki-verified" class="gl-shrink-0 gl-text-blue-500" />
      <span>{{
        s__(
          "CiCatalog|Components created and maintained by GitLab, available to everyone in your organization. These are your organization's trusted components.",
        )
      }}</span>
    </div>

    <div class="gl-mt-4 gl-flex gl-flex-col gl-gap-3 @md/panel:gl-flex-row">
      <gl-search-box-by-type
        v-model="searchTerm"
        class="gl-grow"
        :placeholder="s__('CiCatalog|Search components')"
      />
      <gl-sorting
        :text="selectedSortText"
        :sort-options="sortItems"
        :sort-by="selectedSort"
        :is-ascending="isAscending"
        @sortByChange="onSortSelect"
        @sortDirectionChange="onSortDirectionToggle"
      />
    </div>

    <gl-loading-icon v-if="isLoading" size="lg" class="gl-mt-5" />

    <gl-empty-state
      v-else-if="showEmptyState"
      class="gl-mt-5"
      :title="emptyStateLabels.title"
      :description="emptyStateLabels.description"
      :svg-path="isSearching ? $options.FILTERED_SVG_URL : $options.EMPTY_SVG_URL"
    />

    <ul v-else class="gl-mt-3 gl-p-0" data-testid="cells-list">
      <ci-resources-list-item
        v-for="resource in filteredResources"
        :key="resource.id"
        :resource="resource"
        :show-stats="!isBundledTab"
        :show-author="!isBundledTab"
      />
    </ul>
  </div>
</template>
