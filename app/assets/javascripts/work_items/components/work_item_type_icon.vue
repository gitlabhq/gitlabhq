<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { WORK_ITEMS_TYPE_MAP } from '../constants';

export default {
  components: {
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
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
    showTooltipOnHover: {
      type: Boolean,
      required: false,
      default: false,
    },
    iconVariant: {
      type: String,
      required: false,
      default: 'default',
    },
    iconClass: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    workItemTypeUppercase() {
      return this.workItemType.toUpperCase().split(' ').join('_');
    },
    iconName() {
      // TODO Delete this conditional once we have an `issue-type-epic` icon
      if (this.workItemIconName === 'issue-type-epic') {
        return 'epic';
      }

      return (
        this.workItemIconName ||
        WORK_ITEMS_TYPE_MAP[this.workItemTypeUppercase]?.icon ||
        'issue-type-issue'
      );
    },
    workItemTypeName() {
      return WORK_ITEMS_TYPE_MAP[this.workItemTypeUppercase]?.name;
    },
    workItemTooltipTitle() {
      return this.showTooltipOnHover ? this.workItemTypeName : '';
    },
  },
};
</script>

<template>
  <span>
    <gl-icon
      v-gl-tooltip.hover="showTooltipOnHover"
      :name="iconName"
      :title="workItemTooltipTitle"
      :variant="iconVariant"
      :class="iconClass"
    />
    <span v-if="workItemTypeName" :class="{ 'gl-sr-only': !showText }">{{ workItemTypeName }}</span>
  </span>
</template>
