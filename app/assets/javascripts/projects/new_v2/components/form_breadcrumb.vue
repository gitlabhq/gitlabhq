<script>
import { GlBreadcrumb } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  components: {
    GlBreadcrumb,
  },
  inject: ['rootPath', 'projectsUrl', 'parentGroupUrl', 'parentGroupName'],
  props: {
    selectedProjectType: {
      type: Object,
      required: false,
      default: null,
    },
  },
  computed: {
    breadcrumbs() {
      const breadcrumbs = this.parentGroupUrl
        ? [{ text: this.parentGroupName, href: this.parentGroupUrl }]
        : [
            { text: s__('Navigation|Your work'), href: this.rootPath },
            { text: s__('ProjectsNew|Projects'), href: this.projectsUrl },
          ];
      breadcrumbs.push({ text: s__('ProjectsNew|New project'), href: '#' });

      if (this.selectedProjectType) {
        breadcrumbs.push({
          text: this.selectedProjectType.title,
          href: `#${this.selectedProjectType.value}`,
        });
      }

      return breadcrumbs;
    },
  },
};
</script>

<template>
  <div class="top-bar-fixed container-fluid" data-testid="top-bar">
    <div class="top-bar-container gl-border-b gl-flex gl-items-center gl-gap-2">
      <gl-breadcrumb :items="breadcrumbs" data-testid="breadcrumb-links" class="gl-grow" />
    </div>
  </div>
</template>
