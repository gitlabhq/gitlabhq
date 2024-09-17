<script>
import { GlLoadingIcon, GlKeysetPagination } from '@gitlab/ui';
import groupsEmptyStateSvgPath from '@gitlab/svgs/dist/illustrations/empty-state/empty-groups-md.svg?url';
import { createAlert } from '~/alert';
import { s__, __ } from '~/locale';
import GroupsList from '~/vue_shared/components/groups_list/groups_list.vue';
import { ACTION_DELETE } from '~/vue_shared/components/list_actions/constants';
import { DEFAULT_PER_PAGE } from '~/api';
import axios from '~/lib/utils/axios_utils';
import { formatGroups, timestampType } from '~/organizations/shared/utils';
import {
  renderDeleteSuccessToast,
  deleteParams,
} from 'ee_else_ce/vue_shared/components/resource_lists/utils';
import groupsQuery from '../graphql/queries/groups.query.graphql';
import { SORT_ITEM_NAME, SORT_DIRECTION_ASC } from '../constants';
import NewGroupButton from './new_group_button.vue';
import GroupsAndProjectsEmptyState from './groups_and_projects_empty_state.vue';

export default {
  groupsEmptyStateSvgPath,
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
    group: __('Group'),
  },
  components: {
    GlLoadingIcon,
    GlKeysetPagination,
    GroupsList,
    NewGroupButton,
    GroupsAndProjectsEmptyState,
  },
  inject: {
    organizationGid: {},
    groupsPath: {},
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
    timestampType() {
      return timestampType(this.sortName);
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
        await axios.delete(this.groupsPath, {
          params: { id: group.fullPath, ...deleteParams(group) },
        });
        this.$apollo.queries.groups.refetch();
        renderDeleteSuccessToast(group, this.$options.i18n.group);
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
      :timestamp-type="timestampType"
      @delete="deleteGroup"
    />

    <div v-if="pageInfo.hasNextPage || pageInfo.hasPreviousPage" class="gl-mt-5 gl-text-center">
      <gl-keyset-pagination v-bind="pageInfo" @prev="onPrev" @next="onNext" />
    </div>
  </div>
  <groups-and-projects-empty-state
    v-else
    :svg-path="$options.groupsEmptyStateSvgPath"
    :title="$options.i18n.emptyState.title"
    :description="$options.i18n.emptyState.description"
    :search="search"
  >
    <template v-if="shouldShowEmptyStateButtons" #actions>
      <new-group-button />
    </template>
  </groups-and-projects-empty-state>
</template>
