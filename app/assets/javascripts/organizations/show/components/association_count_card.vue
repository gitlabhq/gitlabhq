<script>
import { GlIcon, GlLink, GlCard } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'AssociationCountCard',
  components: { GlIcon, GlLink, GlCard },
  props: {
    title: {
      type: String,
      required: true,
    },
    iconName: {
      type: String,
      required: true,
    },
    count: {
      type: String,
      required: true,
    },
    linkHref: {
      type: String,
      required: true,
    },
    linkText: {
      type: String,
      required: false,
      default: __('View all'),
    },
  },
};
</script>

<template>
  <gl-card>
    <div class="gl-display-flex gl-align-items-center gl-justify-content-space-between">
      <div class="gl-display-flex gl-align-items-center gl-text-gray-700">
        <gl-icon :name="iconName" />
        <span class="gl-ml-2">{{ title }}</span>
      </div>
      <gl-link :href="linkHref">{{ linkText }}</gl-link>
    </div>
    <span
      class="gl-font-size-h-display gl-font-weight-bold gl-line-height-ratio-1000 gl-mt-2 gl-display-block"
      >{{ count }}</span
    >
  </gl-card>
</template>
