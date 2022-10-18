<script>
import { GlEmptyState } from '@gitlab/ui';
import PaginationLinks from '~/vue_shared/components/pagination_links.vue';
import { getParameterByName } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import eventHub from '../event_hub';

export default {
  i18n: {
    emptyStateTitle: __('No results found'),
    emptyStateDescription: __('Edit your search and try again'),
  },
  components: {
    PaginationLinks,
    GlEmptyState,
  },
  props: {
    groups: {
      type: Array,
      required: true,
    },
    pageInfo: {
      type: Object,
      required: true,
    },
    searchEmpty: {
      type: Boolean,
      required: true,
    },
    action: {
      type: String,
      required: false,
      default: '',
    },
  },
  methods: {
    change(page) {
      const filterGroupsBy = getParameterByName('filter');
      const sortBy = getParameterByName('sort');
      const archived = getParameterByName('archived');
      eventHub.$emit(`${this.action}fetchPage`, { page, filterGroupsBy, sortBy, archived });
    },
  },
};
</script>

<template>
  <div class="groups-list-tree-container" data-qa-selector="groups_list_tree_container">
    <gl-empty-state
      v-if="searchEmpty"
      :title="$options.i18n.emptyStateTitle"
      :description="$options.i18n.emptyStateDescription"
    />
    <template v-else>
      <group-folder :groups="groups" :action="action" />
      <pagination-links
        :change="change"
        :page-info="pageInfo"
        class="d-flex justify-content-center gl-mt-3"
      />
    </template>
  </div>
</template>
