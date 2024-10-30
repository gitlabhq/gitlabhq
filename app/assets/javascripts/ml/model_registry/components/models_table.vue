<script>
import { GlAvatarLink, GlAvatar, GlTable, GlLink, GlTooltip } from '@gitlab/ui';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { s__ } from '~/locale';

export default {
  name: 'ModelsTable',
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
    tableFields() {
      return [
        { key: 'name', label: s__('ModelRegistry|Model name'), thClass: 'gl-w-1/4' },
        { key: 'latestVersion', label: s__('ModelRegistry|Latest version'), thClass: 'gl-w-1/4' },
        { key: 'author', label: s__('ModelRegistry|Author'), thClass: 'gl-w-1/4' },
        { key: 'createdAt', label: s__('ModelRegistry|Created'), thClass: 'gl-w-1/4' },
      ];
    },
  },
  methods: {
    versionLabel(item) {
      return item.versionCount === 1 ? s__('ModelRegistry|version') : s__('ModelRegistry|versions');
    },
    showLatestVersion(item) {
      return item.latestVersion && item.latestVersion._links;
    },
  },
};
</script>

<template>
  <gl-table class="fixed" :sticky-header="false" :items="items" :fields="tableFields" stacked="sm">
    <template #cell(name)="{ item }">
      <gl-link :href="item._links.showPath">
        {{ item.name }}
      </gl-link>
    </template>
    <template #cell(latestVersion)="{ item }">
      <gl-link v-if="showLatestVersion(item)" :href="item.latestVersion._links.showPath">
        {{ item.latestVersion.version }}
      </gl-link>
      <span v-if="item.latestVersion" class="gl-text-subtle"> · </span>
      <span class="gl-text-subtle">{{ item.versionCount }} {{ versionLabel(item) }}</span>
    </template>
    <template #cell(author)="{ item: { author } }">
      <gl-avatar-link
        v-if="author"
        :href="author.webUrl"
        :title="author.name"
        class="js-user-link gl-text-subtle"
      >
        <gl-avatar :src="author.avatarUrl" :size="16" :entity-name="author.name" class="mr-2" />
        {{ author.name }}
      </gl-avatar-link>
    </template>
    <template #cell(createdAt)="{ item: { createdAt } }">
      <time-ago-tooltip v-if="createdAt" :time="createdAt" />
    </template>
  </gl-table>
</template>
