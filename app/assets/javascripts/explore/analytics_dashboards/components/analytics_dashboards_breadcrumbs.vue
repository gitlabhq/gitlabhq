<script>
import { GlBreadcrumb } from '@gitlab/ui';

export default {
  name: 'AnalyticsDashboardsBreadcrumbs',
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
    isRootRoute() {
      return this.$route.name === this.rootRoute.name;
    },
    rootRouteName() {
      return this.rootRoute.meta.getName();
    },
    routeName() {
      return this.$route.meta.getName();
    },
    intermediaryRoutes() {
      const { getParents } = this.$route.meta;
      return getParents ? getParents() : [];
    },
    rootRoutePath() {
      return this.rootRoute.path;
    },
    allCrumbs() {
      const crumbs = [
        {
          text: this.rootRouteName,
          to: this.rootRoutePath,
        },
      ];

      if (!this.isRootRoute) {
        // Add all intermediary routes (between the root and the current route)
        crumbs.push(...this.intermediaryRoutes);

        // Add current route
        if (this.routeName) {
          crumbs.push({
            text: this.routeName,
            // Setting this to undefined allows us to keep the query params in
            // the event the user clicks on the breadcrumb for the current route
            to: undefined,
          });
        }
      }

      return [...this.staticBreadcrumbs, ...crumbs];
    },
  },
};
</script>

<template>
  <gl-breadcrumb :items="allCrumbs" :auto-resize="false" class="gl-grow" />
</template>
