<script>
import { GlAlert, GlSprintf, GlTab, GlTabs } from '@gitlab/ui';
import { updateHistory } from '~/lib/utils/url_utility';
import { InternalEvents } from '~/tracking';

const trackingMixin = InternalEvents.mixin();

export default {
  name: 'UsageQuotasApp',
  components: { GlAlert, GlSprintf, GlTab, GlTabs },
  mixins: [trackingMixin],
  inject: ['tabs'],
  methods: {
    glTabLinkAttributes(tab) {
      return { 'data-testid': tab.testid };
    },
    isActive(hash) {
      const activeTabHash = new URL(window.location.href).hash;

      return activeTabHash === hash;
    },
    updateActiveTab(tab) {
      const url = new URL(window.location.href);

      url.hash = tab.hash;

      updateHistory({
        url,
        title: document.title,
        replace: true,
      });

      if (tab.tracking?.action) {
        this.trackEvent(tab.tracking.action);
      }
    },
  },
};
</script>

<template>
  <section>
    <gl-alert v-if="!tabs.length" variant="danger" :dismissible="false">
      {{ s__('UsageQuota|Something went wrong while loading Usage Quotas Tabs.') }}
    </gl-alert>
    <gl-tabs v-else content-class="gl-leading-[unset]">
      <gl-tab
        v-for="tab in tabs"
        :key="tab.hash"
        :title="tab.title"
        :active="isActive(tab.hash)"
        :data-testid="`${tab.testid}-tab-content`"
        :title-link-attributes="glTabLinkAttributes(tab)"
        lazy
        @click="updateActiveTab(tab)"
      >
        <component :is="tab.component" :data-testid="`${tab.testid}-app`" />
      </gl-tab>
    </gl-tabs>
  </section>
</template>
