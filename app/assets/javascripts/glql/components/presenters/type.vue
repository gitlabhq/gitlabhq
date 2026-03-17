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
    workItemTypeIconName() {
      return typeof this.data === 'object' ? this.data.iconName : '';
    },
  },
};
</script>
<template>
  <work-item-type-icon
    :work-item-type="workItemType"
    :type-icon-name="workItemTypeIconName"
    :show-text="true"
    class="gl-whitespace-nowrap"
  />
</template>
