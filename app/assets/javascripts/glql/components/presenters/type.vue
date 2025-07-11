<script>
import WorkItemTypeIcon from '~/work_items/components/work_item_type_icon.vue';

export default {
  name: 'TypePresenter',
  components: {
    WorkItemTypeIcon,
  },
  props: {
    data: {
      required: true,
      type: [String, Object],
    },
  },
  computed: {
    workItemType() {
      return typeof this.data === 'string' ? this.data : this.data.name;
    },
  },
};
</script>
<template>
  <work-item-type-icon :work-item-type="workItemType" :show-text="true" />
</template>
