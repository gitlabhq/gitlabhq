<script>
// We are using gl-breadcrumb only at the last child of the handwritten breadcrumb
// until this gitlab-ui issue is resolved: https://gitlab.com/gitlab-org/gitlab-ui/-/issues/1079
//
// See the CSS workaround in app/assets/stylesheets/pages/registry.scss when this file is changed.
import { GlBreadcrumb, GlIcon } from '@gitlab/ui';
import { isArray, last } from 'lodash';

export default {
  components: {
    GlBreadcrumb,
    GlIcon,
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

      return routeInfoList;
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
      return crumbs;
    },
  },
};
</script>

<template>
  <gl-breadcrumb :key="isLoaded" :items="allCrumbs">
    <template #separator>
      <span class="gl-mx-n5">
        <gl-icon name="chevron-lg-right" :size="8" />
      </span>
    </template>
  </gl-breadcrumb>
</template>
