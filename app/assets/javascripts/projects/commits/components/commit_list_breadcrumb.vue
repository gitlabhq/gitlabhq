<script>
import { GlBreadcrumb } from '@gitlab/ui';
import { joinPaths, buildURLwithRefType, escapeFileUrl } from '~/lib/utils/url_utility';

export default {
  name: 'CommitListBreadcrumb',
  components: {
    GlBreadcrumb,
  },
  inject: ['projectFullPath', 'projectPath', 'escapedRef', 'refType'],
  computed: {
    currentPath() {
      return this.$route.params.path || '';
    },
    breadcrumbItems() {
      const items = [];

      const projectRootUrl = buildURLwithRefType({
        path: this.escapedRef,
        refType: this.refType,
      });

      items.push({
        text: this.projectPath,
        to: projectRootUrl,
      });

      if (this.currentPath) {
        const parts = this.currentPath.split('/').filter(Boolean);

        parts.forEach((part, index) => {
          const escapedParts = parts.slice(0, index + 1).map((p) => escapeFileUrl(p));
          const pathUpToHere = escapedParts.join('/');
          const segmentUrl = buildURLwithRefType({
            path: joinPaths(this.escapedRef, pathUpToHere),
            refType: this.refType,
          });

          items.push({
            text: part,
            to: segmentUrl,
          });
        });
      }

      return items;
    },
  },
};
</script>

<template>
  <gl-breadcrumb :items="breadcrumbItems" :aria-label="__('Commits breadcrumb')" size="md" />
</template>
