<script>
// We are using gl-breadcrumb only at the last child of the handwritten breadcrumb
// until this gitlab-ui issue is resolved: https://gitlab.com/gitlab-org/gitlab-ui/-/issues/1079 [CLOSED]
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
      return this.detailsRoute.meta?.nameGenerator() || (this.$route.params?.id ?? '');
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
          to: { name: this.detailsRoute.name, params: this.$route.params },
        });
      }
      return crumbs;
    },
  },
};
</script>

<template>
  <gl-breadcrumb :items="allCrumbs" />
</template>
