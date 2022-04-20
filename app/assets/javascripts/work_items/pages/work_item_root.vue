<script>
import { TYPE_WORK_ITEM } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import WorkItemDetail from '../components/work_item_detail.vue';

export default {
  components: {
    WorkItemDetail,
  },
  props: {
    id: {
      type: String,
      required: true,
    },
  },
  computed: {
    gid() {
      return convertToGraphQLId(TYPE_WORK_ITEM, this.id);
    },
  },
};
</script>

<template>
  <work-item-detail :work-item-id="gid" />
</template>
