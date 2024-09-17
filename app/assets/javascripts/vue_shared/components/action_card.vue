<script>
import { GlIcon, GlLink } from '@gitlab/ui';

export const VARIANTS = {
  default: 'default',
  success: 'success',
  promo: 'promo',
};

export default {
  components: {
    GlIcon,
    GlLink,
  },
  props: {
    title: {
      type: String,
      required: true,
    },
    description: {
      type: String,
      required: true,
    },
    icon: {
      type: String,
      required: true,
    },
    variant: {
      type: String,
      required: false,
      default: VARIANTS.default,
      validator: (variant) => Object.values(VARIANTS).includes(variant),
    },
    href: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    cardIcon() {
      return this.variant === VARIANTS.success ? 'check' : this.icon;
    },
  },
};
</script>

<template>
  <div :class="['action-card', `action-card-${variant}`]">
    <gl-link v-if="href" class="action-card-title" :href="href">
      <gl-icon :name="cardIcon" data-testid="action-card-icon" />
      {{ title }}
      <gl-icon name="arrow-right" class="action-card-arrow" data-testid="action-card-arrow-icon" />
    </gl-link>
    <div v-else class="action-card-title" data-testid="action-card-title">
      <gl-icon :name="cardIcon" data-testid="action-card-icon" />
      {{ title }}
    </div>
    <p class="action-card-text" data-testid="action-card-description">{{ description }}</p>
    <div class="action-card-controls"><slot></slot></div>
  </div>
</template>
