<script>
import { GlBreadcrumb } from '@gitlab/ui';

export default {
  components: {
    GlBreadcrumb,
  },
  props: {
    allStaticBreadcrumbs: {
      required: true,
      type: Array,
    },
  },
  computed: {
    crumbs() {
      // Get the first matched items. Iterate over each of them and make then a breadcrumb item
      // only if they have a meta field with text in
      const { id } = this.$route.params;
      const matchedRoutes = (this.$route?.matched || [])
        .map((route) => {
          const useRouteId = Boolean(route?.meta?.useId);
          const to = route.parent ? { name: route.name } : { path: route.path };
          return {
            text: useRouteId && id ? String(id) : route.meta?.text,
            to,
          };
        })
        .filter((r) => r.text);

      return [...this.allStaticBreadcrumbs, ...matchedRoutes];
    },
  },
};
</script>
<template>
  <gl-breadcrumb :items="crumbs" :auto-resize="false" />
</template>
