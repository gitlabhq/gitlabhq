<script>
import { TYPE_WORK_ITEM } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { s__ } from '~/locale';
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
  methods: {
    handleWorkItemDeleted() {
      this.$root.$toast.show(s__('WorkItem|Work item deleted'));
      this.$router.push('/');
    },
  },
};
</script>

<template>
  <work-item-detail :work-item-id="gid" @workItemDeleted="handleWorkItemDeleted" />
</template>
