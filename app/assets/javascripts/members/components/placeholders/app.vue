<script>
import { GlBadge, GlTab, GlTabs } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  name: 'PlaceholdersTabApp',
  components: {
    GlBadge,
    GlTab,
    GlTabs,
  },
  TABS: [
    {
      title: s__('UserMapping|Awaiting reassignment'),
    },
    {
      title: s__('UserMapping|Reassigned'),
    },
  ],
  data() {
    return {
      selectedTabIndex: 0,
    };
  },
  methods: {
    tabCount() {
      return 0;
    },
  },
};
</script>

<template>
  <gl-tabs v-model="selectedTabIndex" class="gl-mt-3">
    <gl-tab v-for="(tab, index) in $options.TABS" :key="index">
      <template #title>
        <span>{{ tab.title }}</span>
        <gl-badge size="sm" class="gl-tab-counter-badge">{{ tabCount() }}</gl-badge>
      </template>
    </gl-tab>
  </gl-tabs>
</template>
