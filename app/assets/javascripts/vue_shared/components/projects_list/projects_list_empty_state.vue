<script>
import { GlEmptyState } from '@gitlab/ui';
import { __, s__ } from '~/locale';

export default {
  name: 'ProjectsListEmptyState',
  i18n: {
    emptyStateSearchTitle: __('No results found'),
    emptyStateSearchMinCharDescription: __('Search must be at least 3 characters.'),
    emptyStateSearchDescription: __('Edit your criteria and try again.'),
    emptyStateProjectsTitle: s__("Projects|You don't have any projects yet."),
    emptyStateProjectsDescription: s__(
      'Projects|Projects are where you can store your code, access issues, wiki, and other features of GitLab.',
    ),
  },
  components: {
    GlEmptyState,
  },
  inject: ['emptyStateSearchSvgPath', 'emptyStateProjectsSvgPath'],
  props: {
    search: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    hasSearch() {
      return Boolean(this.search);
    },
    svgPath() {
      return this.hasSearch ? this.emptyStateSearchSvgPath : this.emptyStateProjectsSvgPath;
    },
    title() {
      return this.hasSearch
        ? this.$options.i18n.emptyStateSearchTitle
        : this.$options.i18n.emptyStateProjectsTitle;
    },
    description() {
      if (!this.hasSearch) {
        return this.$options.i18n.emptyStateProjectsDescription;
      }

      return this.search.length >= 3
        ? this.$options.i18n.emptyStateSearchDescription
        : this.$options.i18n.emptyStateSearchMinCharDescription;
    },
  },
};
</script>

<template>
  <gl-empty-state :title="title" :description="description" :svg-path="svgPath" />
</template>
