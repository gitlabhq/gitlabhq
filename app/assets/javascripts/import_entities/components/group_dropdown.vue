<script>
import { GlDropdown, GlSearchBoxByType } from '@gitlab/ui';
import { debounce } from 'lodash';

import { s__ } from '~/locale';
import { createAlert } from '~/alert';
import searchNamespacesWhereUserCanImportProjectsQuery from '~/import_entities/import_projects/graphql/queries/search_namespaces_where_user_can_import_projects.query.graphql';
import { DEBOUNCE_DELAY } from '~/vue_shared/components/filtered_search_bar/constants';
import { MINIMUM_SEARCH_LENGTH } from '~/graphql_shared/constants';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';

const reportNamespaceLoadError = debounce(
  () =>
    createAlert({
      message: s__('ImportProjects|Requesting namespaces failed'),
    }),
  DEFAULT_DEBOUNCE_AND_THROTTLE_MS,
);

export default {
  components: {
    GlDropdown,
    GlSearchBoxByType,
  },
  inheritAttrs: false,
  data() {
    return { searchTerm: '' };
  },
  apollo: {
    namespaces: {
      query: searchNamespacesWhereUserCanImportProjectsQuery,
      variables() {
        return {
          search: this.searchTerm,
        };
      },
      skip() {
        const hasNotEnoughSearchCharacters =
          this.searchTerm.length > 0 && this.searchTerm.length < MINIMUM_SEARCH_LENGTH;
        return hasNotEnoughSearchCharacters;
      },
      update(data) {
        return data.currentUser.groups.nodes;
      },
      error: reportNamespaceLoadError,
      debounce: DEBOUNCE_DELAY,
    },
  },
  computed: {
    filteredNamespaces() {
      return (this.namespaces ?? []).filter((ns) =>
        ns.fullPath.toLowerCase().includes(this.searchTerm.toLowerCase()),
      );
    },
  },
};
</script>
<template>
  <gl-dropdown
    toggle-class="gl-rounded-top-right-none! gl-rounded-bottom-right-none!"
    class="gl-h-7 gl-flex-fill-1"
    data-qa-selector="target_namespace_selector_dropdown"
    v-bind="$attrs"
  >
    <template #header>
      <gl-search-box-by-type v-model.trim="searchTerm" />
    </template>
    <slot :namespaces="filteredNamespaces"></slot>
  </gl-dropdown>
</template>
