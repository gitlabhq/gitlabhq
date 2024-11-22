<script>
import { GlTooltip, GlIcon, GlLink } from '@gitlab/ui';

export default {
  components: {
    GlTooltip,
    GlIcon,
    GlLink,
  },
  props: {
    anchorId: {
      type: String,
      required: false,
      default: '',
    },
    wrapperComponent: {
      type: String,
      required: false,
      default: 'span',
    },
    wrapperComponentClass: {
      type: String,
      required: false,
      default: '',
    },
    title: {
      type: String,
      required: false,
      default: '',
    },
    titleComponentClass: {
      type: String,
      required: false,
      default: '',
    },
    iconName: {
      type: String,
      required: false,
      default: '',
    },
    iconClass: {
      type: String,
      required: false,
      default: '',
    },
    tooltipText: {
      type: String,
      required: false,
      default: '',
    },
    tooltipPlacement: {
      type: String,
      required: false,
      default: 'bottom',
    },
    isLink: {
      type: Boolean,
      required: false,
      default: false,
    },
    href: {
      type: String,
      required: false,
      default: '',
    },
  },
};
</script>

<template>
  <component :is="isLink ? 'gl-link' : 'span'" :href="href">
    <!-- wrapper  -->
    <component
      :is="wrapperComponent"
      ref="wrapperRef"
      :class="wrapperComponentClass"
      :data-testid="anchorId"
    >
      <!-- icon  -->
      <slot name="icon">
        <gl-icon
          v-if="iconName"
          :class="iconClass"
          :name="iconName"
          :data-testid="`${anchorId}-icon`"
        />
      </slot>
      <!-- title  -->
      <slot name="title">
        <span v-if="title" :class="titleComponentClass" :data-testid="`${anchorId}-title`">
          {{ title }}
        </span>
      </slot>
    </component>
    <!-- tooltip  -->
    <gl-tooltip :target="() => $refs.wrapperRef" :placement="tooltipPlacement">
      <slot name="tooltip-text">
        <template v-if="tooltipText">
          {{ tooltipText }}
        </template>
      </slot>
    </gl-tooltip>
  </component>
</template>
