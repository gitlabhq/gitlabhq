<script>
import { GlTableLite, GlLink, GlBadge, GlAvatarLink, GlAvatar } from '@gitlab/ui';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { s__ } from '~/locale';

export default {
  name: 'CandidatesTable',
  components: {
    GlAvatarLink,
    GlAvatar,
    GlTableLite,
    TimeAgoTooltip,
    GlLink,
    GlBadge,
  },
  props: {
    items: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  methods: {
    statusBadge(status) {
      return {
        success: 'success',
        failed: 'danger',
        pending: 'info',
        running: 'info',
        canceled: 'warning',
      }[status];
    },
    hasCiJob(item) {
      return item.ciJob;
    },
  },
  tableFields: [
    { key: 'eid', label: s__('ModelRegistry|MLflow Run ID'), thClass: 'gl-w-2/8' },
    { key: 'ciJob', label: s__('ModelRegistry|CI Job'), thClass: 'gl-w-1/8' },
    { key: 'createdAt', label: s__('ModelRegistry|Created'), thClass: 'gl-w-1/8' },
    { key: 'creator', label: s__('ModelRegistry|Created by'), thClass: 'gl-w-2/8' },
    { key: 'status', label: s__('ModelRegistry|Status'), thClass: 'gl-w-1/8' },
  ],
};
</script>

<template>
  <gl-table-lite class="fixed" :items="items" :fields="$options.tableFields" stacked="sm">
    <template #cell(eid)="{ item }">
      <gl-link :href="item._links.showPath">
        {{ item.eid }}
      </gl-link>
    </template>
    <template #cell(ciJob)="{ item }">
      <gl-link v-if="hasCiJob(item)" :href="item.ciJob.webPath">{{ item.ciJob.name }}</gl-link>
    </template>
    <template #cell(createdAt)="{ item: { createdAt } }">
      <time-ago-tooltip v-if="createdAt" :time="createdAt" />
    </template>
    <template #cell(creator)="{ item: { creator } }">
      <gl-avatar-link
        v-if="creator"
        :href="creator.webUrl"
        :title="creator.name"
        class="js-user-link !gl-text-subtle"
      >
        <gl-avatar :src="creator.avatarUrl" :size="16" :entity-name="creator.name" class="mr-2" />
        {{ creator.name }}
      </gl-avatar-link>
    </template>
    <template #cell(status)="{ item }">
      <gl-badge :variant="statusBadge(item.status)">
        {{ item.status }}
      </gl-badge>
    </template>
  </gl-table-lite>
</template>
