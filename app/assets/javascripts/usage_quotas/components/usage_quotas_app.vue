<script>
import { GlAlert, GlSprintf, GlTab, GlTabs } from '@gitlab/ui';
import { updateHistory } from '~/lib/utils/url_utility';

export default {
  name: 'UsageQuotasApp',
  components: { GlAlert, GlSprintf, GlTab, GlTabs },
  inject: ['tabs'],
  methods: {
    isActive(hash) {
      const activeTabHash = new URL(window.location.href).hash;

      return activeTabHash === hash;
    },
    updateActiveTab(hash) {
      const url = new URL(window.location.href);

      url.hash = hash;

      updateHistory({
        url,
        title: document.title,
        replace: true,
      });
    },
  },
};
</script>

<template>
  <section>
    <gl-alert v-if="!tabs.length" variant="danger" :dismissible="false">
      {{ s__('UsageQuota|Something went wrong while loading Usage Quotas Tabs.') }}
    </gl-alert>
    <gl-tabs v-else>
      <gl-tab
        v-for="tab in tabs"
        :key="tab.hash"
        :title="tab.title"
        :active="isActive(tab.hash)"
        :data-testid="tab.hash"
        @click="updateActiveTab(tab.hash)"
      >
        <component :is="tab.component" :data-testid="`${tab.hash}-app`" />
      </gl-tab>
    </gl-tabs>
  </section>
</template>
