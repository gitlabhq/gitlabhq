<script>
import FILTERED_SVG_URL from '@gitlab/svgs/dist/illustrations/empty-state/empty-search-md.svg?url';

import { GlEmptyState, GlLink, GlSprintf } from '@gitlab/ui';
import EMPTY_SVG_URL from '@gitlab/svgs/dist/illustrations/empty-state/empty-catalog-md.svg';
import { s__ } from '~/locale';
import { COMPONENTS_DOCS_URL } from '~/ci/catalog/constants';

export default {
  name: 'CiCatalogEmptyState',
  COMPONENTS_DOCS_URL,
  EMPTY_SVG_URL,
  components: {
    GlEmptyState,
    GlLink,
    GlSprintf,
  },
  props: {
    searchTerm: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    searchLabels() {
      const key = this.isQueryTooSmall ? 'searchTooSmall' : 'search';
      return {
        title: this.$options.i18n[key].title,
        description: this.$options.i18n[key].description,
      };
    },
    isSearching() {
      return this.searchTerm?.length > 0;
    },
    isQueryTooSmall() {
      return this.isSearching && this.searchTerm?.length < 3;
    },
  },
  i18n: {
    default: {
      title: s__('CiCatalog|Get started with the CI/CD Catalog'),
      description: s__(
        'CiCatalog|Create a pipeline component repository and make reusing pipeline configurations faster and easier.',
      ),
    },
    search: {
      title: s__('CiCatalog|No components match your search criteria'),
      description: s__(
        'CiCatalog|Edit your search and try again, or %{linkStart}learn how to create a component project%{linkEnd}.',
      ),
    },
    searchTooSmall: {
      title: s__('CiCatalog|Search incomplete'),
      description: s__('CiCatalog|Search keyword must have at least 3 characters'),
    },
  },
  FILTERED_SVG_URL,
  svgHeight: 145,
};
</script>
<template>
  <div>
    <gl-empty-state
      v-if="isSearching"
      :title="searchLabels.title"
      :svg-path="$options.FILTERED_SVG_URL"
      :svg-height="$options.svgHeight"
    >
      <template #description>
        <gl-sprintf :message="searchLabels.description">
          <template #link="{ content }">
            <gl-link :href="$options.COMPONENTS_DOCS_URL" target="_blank">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </template>
    </gl-empty-state>
    <gl-empty-state
      v-else
      :title="$options.i18n.default.title"
      :description="$options.i18n.default.description"
      :svg-path="$options.EMPTY_SVG_URL"
    />
  </div>
</template>
