<script>
// Since app/assets/javascripts/packages_and_registries/shared/components/registry_breadcrumb.vue
// can only handle two levels of breadcrumbs, but we have three levels here.
// So we extended the registry_breadcrumb.vue component with harbor_registry_breadcrumb.vue to support multiple levels of breadcrumbs
import { GlBreadcrumb } from '@gitlab/ui';
import { isArray, last } from 'lodash';

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
    isRootRoute() {
      return this.$route.name === this.rootRoute.name;
    },
    currentRoute() {
      const currentName = this.$route.meta.nameGenerator();
      const currentHref = this.$route.meta.hrefGenerator();
      let routeInfoList = [
        {
          text: currentName,
          to: currentHref,
        },
      ];

      if (isArray(currentName) && isArray(currentHref)) {
        routeInfoList = currentName.map((name, index) => {
          return {
            text: name,
            to: currentHref[index],
          };
        });
      }

      return [...this.staticBreadcrumbs, ...routeInfoList];
    },
    isLoaded() {
      return this.isRootRoute || last(this.currentRoute).text;
    },
    allCrumbs() {
      let crumbs = [
        {
          text: this.rootRoute.meta.nameGenerator(),
          to: this.rootRoute.path,
        },
      ];
      if (!this.isRootRoute) {
        crumbs = crumbs.concat(this.currentRoute);
      }

      return [...this.staticBreadcrumbs, ...crumbs];
    },
  },
};
</script>

<template>
  <gl-breadcrumb v-if="isLoaded" :items="allCrumbs" />
</template>
