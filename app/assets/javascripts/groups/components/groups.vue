<script>
import tablePagination from '~/vue_shared/components/table_pagination.vue';
import eventHub from '../event_hub';

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
      const filterGroupsParam = gl.utils.getParameterByName('filter_groups');
      const sortParam = gl.utils.getParameterByName('sort');
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
