<script>
import { GlLoadingIcon, GlEmptyState, GlKeysetPagination } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { s__, __ } from '~/locale';
import GroupsList from '~/vue_shared/components/groups_list/groups_list.vue';
import { ACTION_DELETE } from '~/vue_shared/components/list_actions/constants';
import { DEFAULT_PER_PAGE } from '~/api';
import { deleteGroup } from '~/rest_api';
import groupsQuery from '../graphql/queries/groups.query.graphql';
import { SORT_ITEM_NAME, SORT_DIRECTION_ASC } from '../constants';
import { formatGroups } from '../utils';
import NewGroupButton from './new_group_button.vue';

export default {
  i18n: {
    errorMessage: s__(
      'Organization|An error occurred loading the groups. Please refresh the page to try again.',
    ),
    deleteErrorMessage: s__(
      'Organization|An error occurred deleting the group. Please refresh the page to try again.',
    ),
    emptyState: {
      title: s__("Organization|You don't have any groups yet."),
      description: s__(
        'Organization|A group is a collection of several projects. If you organize your projects under a group, it works like a folder.',
      ),
    },
    prev: __('Prev'),
    next: __('Next'),
  },
  components: { GlLoadingIcon, GlEmptyState, GlKeysetPagination, GroupsList, NewGroupButton },
  inject: {
    organizationGid: {},
    groupsEmptyStateSvgPath: {},
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
    search: {
      type: String,
      required: false,
      default: '',
    },
    sortName: {
      type: String,
      required: false,
      default: SORT_ITEM_NAME.value,
    },
    sortDirection: {
      type: String,
      required: false,
      default: SORT_DIRECTION_ASC,
    },
  },
  data() {
    return {
      groups: {},
    };
  },
  apollo: {
    groups: {
      query: groupsQuery,
      variables() {
        return {
          id: this.organizationGid,
          search: this.search,
          sort: this.sort,
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
    pagination() {
      if (!this.startCursor && !this.endCursor) {
        return {
          first: this.perPage,
          after: null,
          last: null,
          before: null,
        };
      }

      return {
        first: this.endCursor && this.perPage,
        after: this.endCursor,
        last: this.startCursor && this.perPage,
        before: this.startCursor,
      };
    },
    sort() {
      return `${this.sortName}_${this.sortDirection}`;
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

      return baseProps;
    },
  },
  methods: {
    onNext(endCursor) {
      this.$emit('page-change', {
        endCursor,
        startCursor: null,
      });
    },
    onPrev(startCursor) {
      this.$emit('page-change', {
        endCursor: null,
        startCursor,
      });
    },
    setGroupIsDeleting(nodeIndex, value) {
      this.groups.nodes[nodeIndex].actionLoadingStates[ACTION_DELETE] = value;
    },
    async deleteGroup(group) {
      const nodeIndex = this.groups.nodes.findIndex((node) => node.id === group.id);

      try {
        this.setGroupIsDeleting(nodeIndex, true);
        await deleteGroup(group.id);
        this.$apollo.queries.groups.refetch();
      } catch (error) {
        createAlert({ message: this.$options.i18n.deleteErrorMessage, error, captureError: true });
      } finally {
        this.setGroupIsDeleting(nodeIndex, false);
      }
    },
  },
};
</script>

<template>
  <gl-loading-icon v-if="isLoading" class="gl-mt-5" size="md" />
  <div v-else-if="nodes.length">
    <groups-list
      :groups="nodes"
      show-group-icon
      :list-item-class="listItemClass"
      @delete="deleteGroup"
    />

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
  <gl-empty-state v-else v-bind="emptyStateProps">
    <template v-if="shouldShowEmptyStateButtons" #actions>
      <new-group-button />
    </template>
  </gl-empty-state>
</template>
