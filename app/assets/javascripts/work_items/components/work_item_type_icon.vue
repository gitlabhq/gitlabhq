<script>
import { GlIcon } from '@gitlab/ui';
import { WORK_ITEMS_TYPE_MAP } from '../constants';

export default {
  components: {
    GlIcon,
  },
  props: {
    workItemType: {
      type: String,
      required: false,
      default: '',
    },
    showText: {
      type: Boolean,
      required: false,
      default: false,
    },
    workItemIconName: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    iconName() {
      return (
        this.workItemIconName || WORK_ITEMS_TYPE_MAP[this.workItemType]?.icon || 'issue-type-issue'
      );
    },
    workItemTypeName() {
      return WORK_ITEMS_TYPE_MAP[this.workItemType]?.name;
    },
  },
};
</script>

<template>
  <span>
    <gl-icon :name="iconName" class="gl-mr-2" />
    <span v-if="workItemTypeName" :class="{ 'gl-sr-only': !showText }">{{ workItemTypeName }}</span>
  </span>
</template>
