<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
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
    typeIconName: {
      type: String,
      required: false,
      default: '',
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
    showDerivedText: {
      type: String,
      required: false,
      default: null,
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
      const name = convertTypeEnumToName(this.workItemTypeEnum);
      return name || this.workItemType;
    },
    iconName() {
      return this.typeIconName || 'work-item-issue';
    },
    workItemTypeText() {
      return this.workItemTypeName || '';
    },
    workItemTooltipTitle() {
      return this.showTooltipOnHover ? this.workItemTypeText : '';
    },
    workItemDerivedText() {
      return this.showDerivedText ? this.showDerivedText : this.workItemTypeText;
    },
  },
};
</script>

<template>
  <button
    v-gl-tooltip="showTooltipOnHover"
    data-testid="work-item-type-icon"
    :title="workItemTooltipTitle"
    :aria-label="workItemTypeText"
    class="!gl-cursor-default gl-border-none gl-bg-transparent gl-p-0 focus-visible:gl-focus-inset"
  >
    <gl-icon :name="iconName" :variant="iconVariant" :class="iconClass" />
    <span v-if="workItemTypeText" :class="{ 'gl-sr-only !gl-absolute': !showText }">{{
      workItemDerivedText
    }}</span>
  </button>
</template>
