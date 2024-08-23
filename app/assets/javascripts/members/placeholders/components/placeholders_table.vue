<script>
import {
  GlAvatarLabeled,
  GlBadge,
  GlEmptyState,
  GlKeysetPagination,
  GlLoadingIcon,
  GlTable,
  GlTooltipDirective,
} from '@gitlab/ui';
import { createAlert } from '~/alert';
import { __, s__ } from '~/locale';

import { DEFAULT_PAGE_SIZE } from '~/members/constants';

import {
  PLACEHOLDER_STATUS_KEPT_AS_PLACEHOLDER,
  PLACEHOLDER_STATUS_COMPLETED,
  placeholderUserBadges,
} from '~/import_entities/import_groups/constants';
import importSourceUsersQuery from '../graphql/queries/import_source_users.query.graphql';
import PlaceholderActions from './placeholder_actions.vue';

const MINIMUM_QUERY_LENGTH = 3;

export default {
  name: 'PlaceholdersTable',
  components: {
    GlAvatarLabeled,
    GlBadge,
    GlEmptyState,
    GlKeysetPagination,
    GlLoadingIcon,
    GlTable,
    PlaceholderActions,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['group'],
  props: {
    queryStatuses: {
      type: Array,
      required: true,
    },
    querySearch: {
      type: String,
      required: false,
      default: null,
    },
    reassigned: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      cursor: {
        before: null,
        after: null,
      },
    };
  },
  apollo: {
    sourceUsers: {
      query: importSourceUsersQuery,
      variables() {
        return {
          fullPath: this.group.path,
          ...this.cursor,
          [this.cursor.before ? 'last' : 'first']: DEFAULT_PAGE_SIZE,
          statuses: this.queryStatuses,
          search: this.querySearch,
        };
      },
      skip() {
        return this.isSearchQueryTooShort;
      },
      update(data) {
        return data.namespace?.importSourceUsers;
      },
      error() {
        createAlert({
          message: s__('UserMapping|There was a problem fetching placeholder users.'),
        });
      },
    },
  },

  computed: {
    fields() {
      return [
        {
          key: 'user',
          label: s__('UserMapping|Placeholder user'),
        },
        {
          key: 'source',
          label: s__('BulkImport|Source'),
        },
        {
          key: 'status',
          label: s__('UserMapping|Reassignment status'),
        },
        {
          key: 'actions',
          label: this.reassigned
            ? s__('UserMapping|Reassigned to')
            : s__('UserMapping|Reassign placeholder to'),
          thClass: 'gl-w-4/10',
        },
      ];
    },
    isLoading() {
      return this.$apollo.queries.sourceUsers.loading;
    },
    nodes() {
      if (this.isSearchQueryTooShort) {
        return [];
      }
      return this.sourceUsers?.nodes || [];
    },
    pageInfo() {
      return this.sourceUsers?.pageInfo || {};
    },
    isSearchQueryTooShort() {
      return this.querySearch && this.querySearch.trim().length < MINIMUM_QUERY_LENGTH;
    },
    emptyText() {
      return this.isSearchQueryTooShort
        ? __('Enter at least three characters to search.')
        : __('Edit your search and try again');
    },
  },

  methods: {
    statusBadge(item) {
      return placeholderUserBadges[item.status];
    },

    isReassignedItem(item) {
      return (
        item.status === PLACEHOLDER_STATUS_KEPT_AS_PLACEHOLDER ||
        item.status === PLACEHOLDER_STATUS_COMPLETED
      );
    },
    reassignedUser(item) {
      if (item.status === PLACEHOLDER_STATUS_KEPT_AS_PLACEHOLDER) {
        return item.placeholderUser;
      }
      if (item.status === PLACEHOLDER_STATUS_COMPLETED) {
        return item.reassignToUser;
      }

      return {};
    },
    onPrevPage() {
      this.cursor = {
        before: this.sourceUsers.pageInfo.startCursor,
        after: null,
      };
    },

    onNextPage() {
      this.cursor = {
        after: this.sourceUsers.pageInfo.endCursor,
        before: null,
      };
    },

    onConfirm(item) {
      this.$emit('confirm', item);
    },
  },
};
</script>

<template>
  <div>
    <gl-table :items="nodes" :fields="fields" :busy="isLoading" show-empty>
      <template #table-busy>
        <gl-loading-icon size="lg" class="gl-my-5" />
      </template>

      <template #empty>
        <gl-empty-state :title="__('No results found')" :description="emptyText" />
      </template>

      <template #cell(user)="{ item }">
        <gl-avatar-labeled
          v-if="item.placeholderUser"
          :size="32"
          :src="item.placeholderUser.avatarUrl"
          :label="item.placeholderUser.name"
          :sub-label="`@${item.placeholderUser.username}`"
        />
      </template>

      <template #cell(source)="{ item }">
        <div>{{ item.sourceHostname }}</div>
        <div class="gl-mt-2">{{ item.sourceUsername }}</div>
      </template>

      <template #cell(status)="{ item }">
        <gl-badge
          v-if="statusBadge(item)"
          v-gl-tooltip="statusBadge(item).tooltip"
          :variant="statusBadge(item).variant"
          tabindex="0"
          >{{ statusBadge(item).text }}</gl-badge
        >
      </template>

      <template #cell(actions)="{ item }">
        <gl-avatar-labeled
          v-if="isReassignedItem(item)"
          :size="32"
          :src="reassignedUser(item).avatarUrl"
          :label="reassignedUser(item).name"
          :sub-label="`@${reassignedUser(item).username}`"
        />
        <placeholder-actions v-else :source-user="item" @confirm="onConfirm(item)" />
      </template>
    </gl-table>

    <div v-if="pageInfo.hasNextPage || pageInfo.hasPreviousPage" class="gl-mt-5 gl-text-center">
      <gl-keyset-pagination
        v-bind="pageInfo"
        :prev-text="__('Prev')"
        :next-text="__('Next')"
        @prev="onPrevPage"
        @next="onNextPage"
      />
    </div>
  </div>
</template>
