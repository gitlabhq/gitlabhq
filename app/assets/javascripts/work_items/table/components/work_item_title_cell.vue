<script>
import { GlTruncate } from '@gitlab/ui';
import WorkItemTypeIcon from '~/work_items/components/work_item_type_icon.vue';

export default {
  name: 'WorkItemTitleCell',
  components: {
    GlTruncate,
    WorkItemTypeIcon,
  },
  props: {
    item: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <span class="gl-flex gl-items-center gl-gap-2">
    <work-item-type-icon
      v-if="item.workItemType"
      :work-item-type="item.workItemType.name"
      :type-icon-name="item.workItemType.iconName"
      icon-variant="subtle"
      class="gl-shrink-0"
    />
    <a
      :href="item.webPath"
      class="gl-min-w-0 gl-text-default hover:gl-text-default"
      data-testid="work-item-link"
    >
      <gl-truncate :text="item.title" with-tooltip />
    </a>
  </span>
</template>
