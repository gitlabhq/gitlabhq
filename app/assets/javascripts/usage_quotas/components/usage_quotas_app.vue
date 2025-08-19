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
  created() {
    if (!this.tabs.length) return;

    let activeTab = this.tabs[0];

    if (window.location.hash.length) {
      const tabByHash = this.tabs.find((tab) => tab.hash === window.location.hash);

      if (tabByHash) {
        activeTab = tabByHash;
      }
    }

    this.handleTabChange(activeTab);
  },
  methods: {
    glTabLinkAttributes(tab) {
      return { 'data-testid': tab.testid };
    },
    isActive(hash) {
      const activeTabHash = new URL(window.location.href).hash;

      return activeTabHash === hash;
    },
    handleTabChange(tab) {
      this.updateFeatureCategory(tab);
      this.updateActiveTab(tab);
    },
    updateFeatureCategory(tab) {
      // NOTE: This is a non-reactive modification of the `gon` object,
      // that won't automatically spread to places of use. Use with caution.
      // Details and further discussion in: https://gitlab.com/gitlab-org/gitlab/-/issues/560771
      gon.feature_category = tab.featureCategory;
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
      {{ s__('UsageQuota|Something went wrong while loading Usage quotas Tabs.') }}
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
        @click="handleTabChange(tab)"
      >
        <component :is="tab.component" :data-testid="`${tab.testid}-app`" />
      </gl-tab>
    </gl-tabs>
  </section>
</template>
