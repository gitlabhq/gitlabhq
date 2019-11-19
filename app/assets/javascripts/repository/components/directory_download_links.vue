<script>
import { GlLink } from '@gitlab/ui';

export default {
  components: {
    GlLink,
  },
  props: {
    currentPath: {
      type: String,
      required: false,
      default: null,
    },
    links: {
      type: Array,
      required: true,
    },
  },
  computed: {
    normalizedLinks() {
      return this.links.map(link => ({
        text: link.text,
        path: `${link.path}?path=${this.currentPath}`,
      }));
    },
  },
};
</script>

<template>
  <section class="border-top pt-1 mt-1">
    <h5 class="m-0 dropdown-bold-header">{{ __('Download this directory') }}</h5>
    <div class="dropdown-menu-content">
      <div class="btn-group ml-0 w-100">
        <gl-link
          v-for="(link, index) in normalizedLinks"
          :key="index"
          :href="link.path"
          :class="{ 'btn-primary': index === 0 }"
          class="btn btn-xs"
        >
          {{ link.text }}
        </gl-link>
      </div>
    </div>
  </section>
</template>
