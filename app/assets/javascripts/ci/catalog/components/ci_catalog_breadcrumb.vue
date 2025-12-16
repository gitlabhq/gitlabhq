<script>
import { GlBreadcrumb } from '@gitlab/ui';
import { CI_RESOURCES_PAGE_NAME, CI_RESOURCES_BREADCRUMB } from '../router/constants';

export default {
  name: 'CiCatalogBreadcrumb',
  components: {
    GlBreadcrumb,
  },
  props: {
    staticBreadcrumbs: {
      type: Array,
      required: true,
    },
  },
  rootRoute: {
    text: CI_RESOURCES_BREADCRUMB,
    to: `/`,
  },
  computed: {
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
      const breadCrumbs = [...this.staticBreadcrumbs, this.$options.rootRoute];

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
