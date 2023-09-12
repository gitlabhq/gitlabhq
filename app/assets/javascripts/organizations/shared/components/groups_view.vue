<script>
import { GlLoadingIcon, GlEmptyState } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { s__, __ } from '~/locale';
import GroupsList from '~/vue_shared/components/groups_list/groups_list.vue';
import groupsQuery from '../graphql/queries/groups.query.graphql';
import { formatGroups } from '../utils';

export default {
  i18n: {
    errorMessage: s__(
      'Organization|An error occurred loading the groups. Please refresh the page to try again.',
    ),
    emptyState: {
      title: s__("Organization|You don't have any groups yet."),
      description: s__(
        'Organization|A group is a collection of several projects. If you organize your projects under a group, it works like a folder.',
      ),
      primaryButtonText: __('New group'),
    },
  },
  components: { GlLoadingIcon, GlEmptyState, GroupsList },
  inject: {
    groupsEmptyStateSvgPath: {},
    newGroupPath: {
      default: null,
    },
  },
  props: {
    shouldShowEmptyStateButtons: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      groups: [],
    };
  },
  apollo: {
    groups: {
      query: groupsQuery,
      update(data) {
        return formatGroups(data.organization.groups.nodes);
      },
      error(error) {
        createAlert({ message: this.$options.i18n.errorMessage, error, captureError: true });
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.groups.loading;
    },
    emptyStateProps() {
      const baseProps = {
        svgHeight: 144,
        svgPath: this.groupsEmptyStateSvgPath,
        title: this.$options.i18n.emptyState.title,
        description: this.$options.i18n.emptyState.description,
      };

      if (this.shouldShowEmptyStateButtons && this.newGroupPath) {
        return {
          ...baseProps,
          primaryButtonLink: this.newGroupPath,
          primaryButtonText: this.$options.i18n.emptyState.primaryButtonText,
        };
      }

      return baseProps;
    },
  },
};
</script>

<template>
  <gl-loading-icon v-if="isLoading" class="gl-mt-5" size="md" />
  <groups-list v-else-if="groups.length" :groups="groups" show-group-icon />
  <gl-empty-state v-else v-bind="emptyStateProps" />
</template>
