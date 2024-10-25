<script>
import { GlAvatarLink, GlAvatar, GlTable, GlLink, GlTooltip } from '@gitlab/ui';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { s__ } from '~/locale';

export default {
  name: 'ModelVersionsTable',
  components: {
    GlAvatarLink,
    GlTable,
    TimeAgoTooltip,
    GlAvatar,
    GlLink,
  },
  directives: {
    GlTooltip,
  },
  props: {
    items: {
      type: Array,
      required: true,
    },
  },
  computed: {
    computedFields() {
      return [
        { key: 'version', label: s__('ModelRegistry|Version'), thClass: 'gl-w-1/3' },
        { key: 'createdAt', label: s__('ModelRegistry|Created'), thClass: 'gl-w-1/3' },
        { key: 'author', label: s__('ModelRegistry|Created by') },
      ];
    },
  },
};
</script>

<template>
  <gl-table class="fixed" :sticky-header="false" :items="items" :fields="computedFields">
    <template #cell(version)="{ item }">
      <gl-link :href="item._links.showPath">
        <b>{{ item.version }}</b>
      </gl-link>
    </template>
    <template #cell(createdAt)="{ item: { createdAt } }">
      <time-ago-tooltip :time="createdAt" />
    </template>
    <template #cell(author)="{ item: { author } }">
      <gl-avatar-link
        :href="author.webUrl"
        :title="author.name"
        class="js-user-link !gl-text-gray-500"
      >
        <gl-avatar :src="author.avatarUrl" :size="16" :entity-name="author.name" class="mr-2" />
        {{ author.name }}
      </gl-avatar-link>
    </template>
  </gl-table>
</template>
