<script>
import tablePagination from '~/vue_shared/components/table_pagination.vue';
import eventHub from '../event_hub';
import { getParameterByName } from '../../lib/utils/common_utils';

export default {
  props: {
    groups: {
      type: Object,
      required: true,
    },
    pageInfo: {
      type: Object,
      required: true,
    },
  },
  components: {
    tablePagination,
  },
  methods: {
    change(page) {
      const filterGroupsParam = getParameterByName('filter_groups');
      const sortParam = getParameterByName('sort');
      eventHub.$emit('fetchPage', page, filterGroupsParam, sortParam);
    },
  },
};
</script>

<template>
  <div class="groups-list-tree-container">
    <group-folder
      :groups="groups"
    />
    <table-pagination
      :change="change"
      :pageInfo="pageInfo"
    />
  </div>
</template>
