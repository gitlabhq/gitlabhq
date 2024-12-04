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
    <div class="gl-flex gl-items-center gl-justify-between">
      <div class="gl-flex gl-items-center gl-text-subtle">
        <gl-icon :name="iconName" />
        <span class="gl-ml-2">{{ title }}</span>
      </div>
      <gl-link :href="linkHref">{{ linkText }}</gl-link>
    </div>
    <span class="gl-mt-2 gl-block gl-text-size-h-display gl-font-bold gl-leading-1">{{
      count
    }}</span>
  </gl-card>
</template>
