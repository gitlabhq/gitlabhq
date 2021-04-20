<script>
import { GlIcon, GlLink } from '@gitlab/ui';

export default {
  components: {
    GlIcon,
    GlLink,
  },
  props: {
    text: {
      type: String,
      required: true,
    },
    url: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div class="d-flex-center gl-flex-nowrap text-nowrap js-ide-status-mr">
    <gl-icon name="merge-request" />
    <span class="ml-1 d-none d-sm-block">{{ s__('WebIDE|Merge request') }}</span>
    <gl-link class="ml-1" :href="url">{{ text }}</gl-link>
  </div>
</template>
