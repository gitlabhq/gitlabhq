<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { get } from 'lodash';
import ProjectsList from '~/vue_shared/components/projects_list/projects_list.vue';
import { __ } from '~/locale';
import { createAlert } from '~/alert';
import { formatGraphQLProjects } from '~/vue_shared/components/projects_list/utils';
import { TIMESTAMP_TYPE_UPDATED_AT } from '~/vue_shared/components/resource_lists/constants';

export default {
  name: 'YourWorkProjectsTabView',
  TIMESTAMP_TYPE_UPDATED_AT,
  i18n: {
    errorMessage: __(
      'An error occurred loading the projects. Please refresh the page to try again.',
    ),
  },
  components: {
    GlLoadingIcon,
    ProjectsList,
  },
  props: {
    tab: {
      required: true,
      type: Object,
    },
  },
  data() {
    return {
      projects: {},
    };
  },
  apollo: {
    projects() {
      return {
        query: this.tab.query,
        update(response) {
          const { nodes, pageInfo } = get(response, this.tab.queryPath);

          return {
            nodes: formatGraphQLProjects(nodes),
            pageInfo,
          };
        },
        error(error) {
          createAlert({ message: this.$options.i18n.errorMessage, error, captureError: true });
        },
      };
    },
  },
  computed: {
    nodes() {
      return this.projects.nodes || [];
    },
    isLoading() {
      return this.$apollo.queries.projects.loading;
    },
  },
  methods: {
    onDeleteComplete() {
      this.$apollo.queries.projects.refetch();
    },
  },
};
</script>

<template>
  <gl-loading-icon v-if="isLoading" class="gl-mt-5" size="md" />
  <projects-list
    v-else-if="nodes.length"
    :projects="nodes"
    show-project-icon
    list-item-class="gl-px-5"
    :timestamp-type="$options.TIMESTAMP_TYPE_UPDATED_AT"
    @delete-complete="onDeleteComplete"
  />
</template>
