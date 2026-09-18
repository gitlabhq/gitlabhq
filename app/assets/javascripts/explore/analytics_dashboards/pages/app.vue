<script>
import { buildDocumentTitle } from '../utils';

export default {
  name: 'ExploreAnalyticsDashboards',
  data() {
    return {
      baseTitle: document.title,
    };
  },
  computed: {
    documentTitle() {
      return buildDocumentTitle(this.$route, this.baseTitle);
    },
  },
  watch: {
    // A router hook would fire before the asynchronous dashboard name arrives.
    documentTitle: {
      immediate: true,
      handler(title) {
        document.title = title;
      },
    },
  },
};
</script>

<template>
  <router-view />
</template>
