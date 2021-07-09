<script>
import PaginationLinks from '~/vue_shared/components/pagination_links.vue';
import { getParameterByName } from '../../lib/utils/url_utility';
import eventHub from '../event_hub';

export default {
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
    searchEmpty: {
      type: Boolean,
      required: true,
    },
    searchEmptyMessage: {
      type: String,
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
      const filterGroupsParam = getParameterByName('filter');
      const sortParam = getParameterByName('sort');
      const archivedParam = getParameterByName('archived');
      eventHub.$emit(`${this.action}fetchPage`, page, filterGroupsParam, sortParam, archivedParam);
    },
  },
};
</script>

<template>
  <div class="groups-list-tree-container qa-groups-list-tree-container">
    <div v-if="searchEmpty" class="has-no-search-results">{{ searchEmptyMessage }}</div>
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
