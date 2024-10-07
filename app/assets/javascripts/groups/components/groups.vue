<!-- eslint-disable vue/multi-word-component-names -->
<script>
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
  <div class="groups-list-tree-container" data-testid="groups-list-tree-container">
    <!-- eslint-disable-next-line vue/no-undef-components -->
    <group-folder :groups="groups" :action="action" />
    <pagination-links
      :change="change"
      :page-info="pageInfo"
      class="gl-mt-3 gl-flex gl-justify-center"
    />
  </div>
</template>
