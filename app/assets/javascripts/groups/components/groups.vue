<script>
import TablePaginationComponent from '~/vue_shared/components/table_pagination';

export default {
  components: {
    'gl-pagination': TablePaginationComponent,
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
  },
  methods: {
    change(pageNumber) {
      const param = gl.utils.setParamInURL('page', pageNumber);

      gl.utils.visitUrl(param);
      return param;
    },
  },
};
</script>

<template>
  <div>
    <group-folder :groups="groups" />
    <gl-pagination
      :change="change"
      :pageInfo="pageInfo" />
  </div>
</template>
