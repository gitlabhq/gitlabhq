<script>
import { GlAvatarLabeled, GlBadge, GlTableLite, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';

import { placeholderUserBadges } from '~/import_entities/import_groups/constants';

export default {
  name: 'PlaceholdersTable',
  components: {
    GlAvatarLabeled,
    GlBadge,
    GlTableLite,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    items: {
      type: Array,
      required: false,
      default: () => [],
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
  },
};
</script>

<template>
  <gl-table-lite :items="items" :fields="fields">
    <template #cell(user)="{ item }">
      <gl-avatar-labeled
        :size="32"
        :src="item.avatar_url"
        :label="item.name"
        :sub-label="item.username"
      />
    </template>

    <template #cell(source)="{ item }">
      <div>{{ item.source_hostname }}</div>
      <div class="gl-mt-2">{{ item.source_username }}</div>
    </template>

    <template #cell(status)="{ item }">
      <gl-badge
        v-gl-tooltip="statusBadge(item).tooltip"
        :variant="statusBadge(item).variant"
        tabindex="0"
        >{{ statusBadge(item).text }}</gl-badge
      >
    </template>
  </gl-table-lite>
</template>
