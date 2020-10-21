<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';

export default {
  components: {
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    title: {
      type: String,
      required: false,
      default: '',
    },
    cssClass: {
      type: String,
      required: false,
      default: '',
    },
    iconName: {
      type: String,
      required: true,
    },
    tooltipPlacement: {
      type: String,
      required: false,
      default: 'bottom',
    },
    /**
     * value could either be number or string
     * as `memberCount` is always passed as string
     * while `subgroupCount` & `projectCount`
     * are always number
     */
    value: {
      type: [Number, String],
      required: false,
      default: '',
    },
  },
  computed: {
    isValuePresent() {
      return this.value !== '';
    },
  },
};
</script>

<template>
  <span
    v-gl-tooltip
    :data-placement="tooltipPlacement"
    :class="cssClass"
    :title="title"
    data-container="body"
  >
    <gl-icon :name="iconName" />
    <span v-if="isValuePresent" class="stat-value" data-testid="itemStatValue"> {{ value }} </span>
  </span>
</template>
