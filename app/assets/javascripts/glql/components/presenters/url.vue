<script>
import { GlLink } from '@gitlab/ui';

export default {
  name: 'UrlPresenter',
  components: {
    GlLink,
  },
  props: {
    data: {
      required: true,
      type: String,
    },
  },
};
</script>
<template>
  <gl-link :href="data">{{ data }}</gl-link>
</template>
