<script>
import { GlTooltip, GlIcon, GlLink, GlTruncate } from '@gitlab/ui';

export default {
  components: {
    GlTooltip,
    GlIcon,
    GlLink,
    GlTruncate,
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
    iconSize: {
      type: Number,
      required: false,
      default: 16,
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
      default: undefined,
    },
    ariaLabel: {
      type: String,
      required: false,
      default: undefined,
    },
  },
  computed: {
    tooltipTarget() {
      return () => {
        const ref = this.$refs.wrapperRef;
        return ref?.$el || ref;
      };
    },
  },
  methods: {
    handleClick(event) {
      this.$emit('click', event);
      if (this.isLink && this.href) {
        event.stopPropagation();
      }
    },
  },
};
</script>

<template>
  <!-- wrapper  -->
  <component
    :is="isLink && href ? 'gl-link' : wrapperComponent"
    ref="wrapperRef"
    class="gl-flex gl-items-center gl-gap-2"
    :class="wrapperComponentClass"
    :href="isLink ? href : null"
    :data-testid="anchorId"
    :aria-label="ariaLabel"
    @click="handleClick"
  >
    <!-- icon  -->
    <slot name="icon">
      <gl-icon
        v-if="iconName"
        variant="subtle"
        :class="['gl-shrink-0', iconClass]"
        :name="iconName"
        :size="iconSize"
        :data-testid="`${anchorId}-icon`"
      />
    </slot>
    <!-- title  -->
    <slot name="title">
      <gl-truncate
        v-if="title"
        :class="titleComponentClass"
        class="gl-min-w-0"
        :data-testid="`${anchorId}-title`"
        :text="title"
      />
    </slot>
    <!-- tooltip  -->
    <gl-tooltip :target="tooltipTarget" :placement="tooltipPlacement">
      <slot name="tooltip-text">
        <template v-if="tooltipText">
          {{ tooltipText }}
        </template>
      </slot>
    </gl-tooltip>
  </component>
</template>
