<script>
import { GlLink } from '@gitlab/ui';

export default {
  name: 'LinkPresenter',
  components: {
    GlLink,
  },
  props: {
    data: {
      required: true,
      type: Object,
      validator: ({ webUrl, webPath, title, username }) =>
        Boolean(webUrl || webPath) && Boolean(title || username),
    },
  },
};
</script>
<template>
  <gl-link :href="data.webUrl || data.webPath">{{ data.title || data.username }}</gl-link>
</template>
