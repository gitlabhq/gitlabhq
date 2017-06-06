<script>
import TablePaginationComponent from '~/vue_shared/components/table_pagination.vue';
import eventHub from '../event_hub';

export default {
  components: {
    'gl-pagination': TablePaginationComponent,
  },
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
  methods: {
    change(page) {
      const filterGroupsParam = gl.utils.getParameterByName('filter_groups');
      const sortParam = gl.utils.getParameterByName('sort');
      eventHub.$emit('fetchPage', page, filterGroupsParam, sortParam);
    },
  },
};
</script>

<template>
  <div class="groups-list-tree-container">
    <group-folder :groups="groups" />
    <gl-pagination
      :change="change"
      :pageInfo="pageInfo" />
  </div>
</template>
