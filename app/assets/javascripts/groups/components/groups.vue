<script>
  import tablePagination from '~/vue_shared/components/table_pagination.vue';
  import eventHub from '../event_hub';
  import { getParameterByName } from '../../lib/utils/common_utils';

  export default {
    components: {
      tablePagination,
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
    },
    methods: {
      change(page) {
        const filterGroupsParam = getParameterByName('filter_groups');
        const sortParam = getParameterByName('sort');
        const archivedParam = getParameterByName('archived');
        eventHub.$emit('fetchPage', page, filterGroupsParam, sortParam, archivedParam);
      },
    },
  };
</script>

<template>
  <div class="groups-list-tree-container">
    <div
      v-if="searchEmpty"
      class="has-no-search-results"
    >
      {{ searchEmptyMessage }}
    </div>
    <group-folder
      v-if="!searchEmpty"
      :groups="groups"
    />
    <table-pagination
      v-if="!searchEmpty"
      :change="change"
      :page-info="pageInfo"
    />
  </div>
</template>
