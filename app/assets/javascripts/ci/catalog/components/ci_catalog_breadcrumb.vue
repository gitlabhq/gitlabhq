<script>
import { GlBreadcrumb } from '@gitlab/ui';
import { CI_RESOURCES_PAGE_NAME, CI_RESOURCES_BREADCRUMB } from '../router/constants';

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
      return {
        text: CI_RESOURCES_BREADCRUMB,
        to: `/`,
      };
    },
    componentRoute() {
      const resourceName = this.resourceId?.split('/').pop();
      return {
        text: resourceName,
        to: this.$route.path,
      };
    },
    isRootRoute() {
      return this.$route.name === CI_RESOURCES_PAGE_NAME;
    },
    resourceId() {
      return this.$route.params.id;
    },
    isLoaded() {
      return Boolean(this.isRootRoute || this.resourceId);
    },
    breadcrumbs() {
      const breadCrumbs = [...this.staticBreadcrumbs, this.rootRoute];

      if (!this.isRootRoute) {
        breadCrumbs.push(this.componentRoute);
      }
      return breadCrumbs;
    },
  },
};
</script>
<template>
  <gl-breadcrumb v-if="isLoaded" :items="breadcrumbs" />
</template>
