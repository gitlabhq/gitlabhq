<script>
import { GlLoadingIcon, GlEmptyState, GlKeysetPagination } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { s__, __ } from '~/locale';
import GroupsList from '~/vue_shared/components/groups_list/groups_list.vue';
import { DEFAULT_PER_PAGE } from '~/api';
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

    prev: __('Prev'),
    next: __('Next'),
  },
  components: { GlLoadingIcon, GlEmptyState, GlKeysetPagination, GroupsList },
  inject: {
    organizationGid: {},
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
    listItemClass: {
      type: [String, Array, Object],
      required: false,
      default: '',
    },
    startCursor: {
      type: String,
      required: false,
      default: null,
    },
    endCursor: {
      type: String,
      required: false,
      default: null,
    },
    perPage: {
      type: Number,
      required: false,
      default: DEFAULT_PER_PAGE,
    },
  },
  data() {
    const baseData = {
      groups: {},
    };

    if (!this.startCursor && !this.endCursor) {
      return {
        ...baseData,
        pagination: {
          first: this.perPage,
          after: null,
          last: null,
          before: null,
        },
      };
    }

    return {
      ...baseData,
      pagination: {
        first: this.endCursor && this.perPage,
        after: this.endCursor,
        last: this.startCursor && this.perPage,
        before: this.startCursor,
      },
    };
  },
  apollo: {
    groups: {
      query: groupsQuery,
      variables() {
        return {
          id: this.organizationGid,
          ...this.pagination,
        };
      },
      update({
        organization: {
          groups: { nodes, pageInfo },
        },
      }) {
        return {
          nodes: formatGroups(nodes),
          pageInfo,
        };
      },
      result() {
        this.$emit('page-change', {
          endCursor: this.pagination.after,
          startCursor: this.pagination.before,
          hasPreviousPage: this.pageInfo.hasPreviousPage,
        });
      },
      error(error) {
        createAlert({ message: this.$options.i18n.errorMessage, error, captureError: true });
      },
    },
  },
  computed: {
    nodes() {
      return this.groups.nodes || [];
    },
    pageInfo() {
      return this.groups.pageInfo || {};
    },
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
  methods: {
    onNext(endCursor) {
      this.pagination = {
        first: this.perPage,
        after: endCursor,
        last: null,
        before: null,
      };
    },
    onPrev(startCursor) {
      this.pagination = {
        first: null,
        after: null,
        last: this.perPage,
        before: startCursor,
      };
    },
  },
};
</script>

<template>
  <gl-loading-icon v-if="isLoading" class="gl-mt-5" size="md" />
  <div v-else-if="nodes.length">
    <groups-list :groups="nodes" show-group-icon :list-item-class="listItemClass" />

    <div v-if="pageInfo.hasNextPage || pageInfo.hasPreviousPage" class="gl-text-center gl-mt-5">
      <gl-keyset-pagination
        v-bind="pageInfo"
        :prev-text="$options.i18n.prev"
        :next-text="$options.i18n.next"
        @prev="onPrev"
        @next="onNext"
      />
    </div>
  </div>
  <gl-empty-state v-else v-bind="emptyStateProps" />
</template>
