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
      validator: ({ webUrl, webPath, title, username, fullName, nameWithNamespace }) =>
        Boolean(webUrl || webPath) && Boolean(title || username || fullName || nameWithNamespace),
    },
  },
  computed: {
    title() {
      return (
        // for issues, work items, merge requests, etc.
        this.data.title ||
        // for users
        this.data.username ||
        // for groups
        this.data.fullName ||
        // for projects
        this.data.nameWithNamespace
      );
    },
  },
};
</script>
<template>
  <gl-link :href="data.webUrl || data.webPath">{{ title }}</gl-link>
</template>
