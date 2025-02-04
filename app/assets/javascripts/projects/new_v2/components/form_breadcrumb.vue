<script>
import { GlBreadcrumb } from '@gitlab/ui';
import { s__ } from '~/locale';
import SuperSidebarToggle from '~/super_sidebar/components/super_sidebar_toggle.vue';
import { JS_TOGGLE_EXPAND_CLASS } from '~/super_sidebar/constants';

export default {
  components: {
    GlBreadcrumb,
    SuperSidebarToggle,
  },
  inject: ['rootPath', 'projectsUrl', 'parentGroupUrl', 'parentGroupName'],
  computed: {
    breadcrumbs() {
      const breadcrumbs = this.parentGroupUrl
        ? [{ text: this.parentGroupName, href: this.parentGroupUrl }]
        : [
            { text: s__('Navigation|Your work'), href: this.rootPath },
            { text: s__('ProjectsNew|Projects'), href: this.projectsUrl },
          ];
      breadcrumbs.push({ text: s__('ProjectsNew|New project'), href: '#' });
      return breadcrumbs;
    },
  },
  JS_TOGGLE_EXPAND_CLASS,
};
</script>

<template>
  <div class="top-bar-fixed container-fluid" data-testid="top-bar">
    <div class="top-bar-container gl-border-b gl-flex gl-items-center gl-gap-2">
      <super-sidebar-toggle :class="$options.JS_TOGGLE_EXPAND_CLASS" class="xl:gl-hidden" />
      <gl-breadcrumb :items="breadcrumbs" data-testid="breadcrumb-links" class="gl-grow" />
    </div>
  </div>
</template>
