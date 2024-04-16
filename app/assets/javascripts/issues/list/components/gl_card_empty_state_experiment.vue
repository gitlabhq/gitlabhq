<script>
import { GlCard, GlIcon } from '@gitlab/ui';

export default {
  components: {
    GlCard,
    GlIcon,
  },
  props: {
    icon: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <gl-card class="gl-text-left gl-hover-bg-blue-50">
    <div class="gl-display-flex gl-gap-4">
      <div class="gl-display-flex gl-my-auto gl-bg-blue-100 gl-rounded-full gl-min-w-8 gl-min-h-8">
        <gl-icon class="gl-display-flex gl-m-auto gl-text-gray-900" :name="icon" />
      </div>

      <div class="gl-w-31">
        <p class="gl-heading-4 gl-mb-1!">
          <slot name="header"></slot>
        </p>

        <slot name="body"></slot>
      </div>
    </div>
  </gl-card>
</template>
