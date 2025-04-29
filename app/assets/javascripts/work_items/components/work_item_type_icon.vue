<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { NAME_TO_ICON_MAP, NAME_TO_TEXT_MAP } from '../constants';
import { convertTypeEnumToName } from '../utils';

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
      required: true,
    },
    showText: {
      type: Boolean,
      required: false,
      default: false,
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
    workItemTypeEnum() {
      // Since this component is used by work items and legacy issues, workItemType can be
      // a legacy issue type or work item name, so normalize it into a work item enum
      return this.workItemType.replaceAll(' ', '_').toUpperCase();
    },
    workItemTypeName() {
      return convertTypeEnumToName(this.workItemTypeEnum);
    },
    iconName() {
      return NAME_TO_ICON_MAP[this.workItemTypeName] || 'issue-type-issue';
    },
    workItemTypeText() {
      return NAME_TO_TEXT_MAP[this.workItemTypeName];
    },
    workItemTooltipTitle() {
      return this.showTooltipOnHover ? this.workItemTypeText : '';
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
    <span v-if="workItemTypeText" :class="{ 'gl-sr-only': !showText }">{{ workItemTypeText }}</span>
  </span>
</template>
