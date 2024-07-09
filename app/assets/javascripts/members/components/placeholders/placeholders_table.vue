<script>
import {
  GlAvatarLabeled,
  GlBadge,
  GlKeysetPagination,
  GlLoadingIcon,
  GlTable,
  GlTooltipDirective,
} from '@gitlab/ui';
import { s__ } from '~/locale';

import {
  PLACEHOLDER_STATUS_KEPT_AS_PLACEHOLDER,
  PLACEHOLDER_STATUS_COMPLETED,
  placeholderUserBadges,
} from '~/import_entities/import_groups/constants';
import PlaceholderActions from './placeholder_actions.vue';

export default {
  name: 'PlaceholdersTable',
  components: {
    GlAvatarLabeled,
    GlBadge,
    GlKeysetPagination,
    GlLoadingIcon,
    GlTable,
    PlaceholderActions,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    isLoading: {
      type: Boolean,
      required: true,
    },
    items: {
      type: Array,
      required: false,
      default: () => [],
    },
    pageInfo: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    reassigned: {
      type: Boolean,
      required: false,
      default: false,
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
    reassginedUser(item) {
      if (item.status === PLACEHOLDER_STATUS_KEPT_AS_PLACEHOLDER) {
        return item.placeholderUser;
      }
      if (item.status === PLACEHOLDER_STATUS_COMPLETED) {
        return item.reassignToUser;
      }

      return {};
    },
  },
};
</script>

<template>
  <div>
    <gl-table :items="items" :fields="fields" :busy="isLoading">
      <template #table-busy>
        <gl-loading-icon size="lg" class="gl-my-5" />
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
          :src="reassginedUser(item).avatarUrl"
          :label="reassginedUser(item).name"
          :sub-label="`@${reassginedUser(item).username}`"
        />
        <placeholder-actions v-else :source-user="item" />
      </template>
    </gl-table>

    <div v-if="pageInfo.hasNextPage || pageInfo.hasPreviousPage" class="gl-text-center gl-mt-5">
      <gl-keyset-pagination
        v-bind="pageInfo"
        :prev-text="__('Prev')"
        :next-text="__('Next')"
        @prev="$emit('prev')"
        @next="$emit('next')"
      />
    </div>
  </div>
</template>
