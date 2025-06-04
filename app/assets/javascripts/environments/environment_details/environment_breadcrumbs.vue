<script>
import { GlBreadcrumb } from '@gitlab/ui';

export default {
  components: {
    GlBreadcrumb,
  },
  props: {
    staticBreadcrumbs: {
      type: Array,
      required: true,
    },
  },
  computed: {
    rootRoute() {
      const rootName = this.$route.meta.environmentName;
      return {
        text: rootName,
        to: `/`,
      };
    },
    logsRoute() {
      const { podName } = this.$route.params;
      return {
        text: `${podName}`,
        to: this.$route.path,
      };
    },
    isRootRoute() {
      return this.$route.name === 'environment_details';
    },
    isLoaded() {
      return Boolean(this.$route.meta.environmentName);
    },
    breadcrumbs() {
      if (!this.isLoaded) {
        return [];
      }
      const breadCrumbs = [...this.staticBreadcrumbs, this.rootRoute];

      if (!this.isRootRoute) {
        breadCrumbs.push(this.logsRoute);
      }
      return breadCrumbs;
    },
  },
};
</script>
<template>
  <gl-breadcrumb v-if="isLoaded" :items="breadcrumbs" />
</template>
