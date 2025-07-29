<script>
// We are using gl-breadcrumb only at the last child of the handwritten breadcrumb
// until this gitlab-ui issue is resolved: https://gitlab.com/gitlab-org/gitlab-ui/-/issues/1079 [CLOSED]
//
// See the CSS workaround in app/assets/stylesheets/pages/registry.scss when this file is changed.
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
      return this.$router.options.routes.find((r) => r.meta.root);
    },
    detailsRoute() {
      return this.$router.options.routes.find((r) => r.name === 'details');
    },
    isRootRoute() {
      return this.$route.name === this.rootRoute.name;
    },
    detailsRouteName() {
      return `${this.$route.params?.id}`;
    },
    isLoaded() {
      return this.isRootRoute || this.detailsRouteName;
    },
    allCrumbs() {
      const crumbs = [
        ...this.staticBreadcrumbs,
        {
          text: this.rootRoute.meta.nameGenerator(),
          to: this.rootRoute.path,
        },
      ];
      if (!this.isRootRoute) {
        crumbs.push({
          text: this.detailsRouteName,
          href: this.detailsRoute.path,
        });
      }
      return crumbs;
    },
  },
};
</script>

<template>
  <gl-breadcrumb :key="isLoaded" :items="allCrumbs" :auto-resize="false" />
</template>
