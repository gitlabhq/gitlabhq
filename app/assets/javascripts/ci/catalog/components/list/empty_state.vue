<script>
import { GlEmptyState, GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import { COMPONENTS_DOCS_URL } from '~/ci/catalog/constants';

export default {
  name: 'CiCatalogEmptyState',
  COMPONENTS_DOCS_URL,
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
    searchTitle() {
      return this.isQueryTooSmall
        ? this.$options.i18n.searchTooSmall.title
        : this.$options.i18n.search.title;
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
      title: s__('CiCatalog|No result found'),
      description: s__(
        'CiCatalog|Edit your search and try again. Or %{linkStart}learn to create a component repository%{linkEnd}.',
      ),
    },
    searchTooSmall: {
      title: s__('CiCatalog|Search must be at least 3 characters'),
    },
  },
};
</script>
<template>
  <div>
    <gl-empty-state v-if="isSearching" :title="searchTitle">
      <template #description>
        <gl-sprintf :message="$options.i18n.search.description">
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
    />
  </div>
</template>
