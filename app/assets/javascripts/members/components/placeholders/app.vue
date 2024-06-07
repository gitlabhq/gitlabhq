<script>
import { GlBadge, GlTab, GlTabs } from '@gitlab/ui';
import PlaceholdersTable from './placeholders_table.vue';

export default {
  name: 'PlaceholdersTabApp',
  components: {
    GlBadge,
    GlTab,
    GlTabs,
    PlaceholdersTable,
  },

  data() {
    return {
      selectedTabIndex: 0,
    };
  },

  computed: {
    tabCount() {
      // WIP: https://gitlab.com/groups/gitlab-org/-/epics/12378
      return 0;
    },
  },
};
</script>

<template>
  <gl-tabs v-model="selectedTabIndex" class="gl-mt-3">
    <gl-tab>
      <template #title>
        <span>{{ s__('UserMapping|Awaiting reassignment') }}</span>
        <gl-badge size="sm" class="gl-tab-counter-badge">{{ tabCount }}</gl-badge>
      </template>

      <placeholders-table key="unassigned" />
    </gl-tab>

    <gl-tab>
      <template #title>
        <span>{{ s__('UserMapping|Reassigned') }}</span>
        <gl-badge size="sm" class="gl-tab-counter-badge">{{ tabCount }}</gl-badge>
      </template>

      <placeholders-table key="assigned" reassigned />
    </gl-tab>
  </gl-tabs>
</template>
