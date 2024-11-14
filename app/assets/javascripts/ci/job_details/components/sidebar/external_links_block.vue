<script>
import { GlIcon, GlLink } from '@gitlab/ui';

export default {
  components: {
    GlIcon,
    GlLink,
  },
  props: {
    externalLinks: {
      type: Array,
      required: true,
    },
  },
};
</script>
<template>
  <div>
    <div class="title gl-font-bold">{{ s__('Job|External links') }}</div>
    <ul class="gl-m-0 gl-list-none gl-p-0">
      <li v-for="(externalLink, index) in externalLinks" :key="index">
        <gl-link :href="externalLink.url" target="_blank" rel="noopener noreferrer nofollow">
          <gl-icon name="external-link" class="flex-shrink-0" />
          {{ externalLink.label }}
        </gl-link>
      </li>
    </ul>
  </div>
</template>
