<script>
import { GlEmptyState } from '@gitlab/ui';
import emptyStateSearchSvgPath from '@gitlab/svgs/dist/illustrations/empty-state/empty-search-md.svg?url';
import emptyStateProjectsSvgPath from '@gitlab/svgs/dist/illustrations/empty-state/empty-projects-md.svg?url';
import { __, s__ } from '~/locale';

export default {
  name: 'ProjectsListEmptyState',
  i18n: {
    emptyStateSearchTitle: __('No results found'),
    emptyStateSearchMinCharDescription: __('Search must be at least 3 characters.'),
    emptyStateSearchDescription: __('Edit your criteria and try again.'),
  },
  components: {
    GlEmptyState,
  },
  props: {
    search: {
      type: String,
      required: false,
      default: '',
    },
    title: {
      type: String,
      required: false,
      default: s__("Projects|You don't have any projects yet."),
    },
    description: {
      type: String,
      required: false,
      default: s__(
        'Projects|Projects are where you can store your code, access issues, wiki, and other features of GitLab.',
      ),
    },
  },
  computed: {
    hasSearch() {
      return Boolean(this.search);
    },
    svgPath() {
      return this.hasSearch ? emptyStateSearchSvgPath : emptyStateProjectsSvgPath;
    },
    computedTitle() {
      return this.hasSearch ? this.$options.i18n.emptyStateSearchTitle : this.title;
    },
    computedDescription() {
      if (!this.hasSearch) {
        return this.description;
      }

      return this.search.length >= 3
        ? this.$options.i18n.emptyStateSearchDescription
        : this.$options.i18n.emptyStateSearchMinCharDescription;
    },
  },
};
</script>

<template>
  <gl-empty-state
    content-class="gl-max-w-75"
    :title="computedTitle"
    :description="computedDescription"
    :svg-path="svgPath"
  />
</template>
