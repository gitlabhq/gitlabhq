<script>
import { GlAlert, GlSprintf, GlTab, GlTabs } from '@gitlab/ui';
import { USAGE_QUOTAS_TITLE, USAGE_QUOTAS_SUBTITLE } from '../constants';

export default {
  name: 'UsageQuotasApp',
  components: { GlAlert, GlSprintf, GlTab, GlTabs },
  inject: ['namespaceName', 'tabs'],
  i18n: {
    USAGE_QUOTAS_TITLE,
    USAGE_QUOTAS_SUBTITLE,
  },
};
</script>

<template>
  <section>
    <h1>{{ $options.i18n.USAGE_QUOTAS_TITLE }}</h1>
    <p data-testid="usage-quotas-page-subtitle">
      <gl-sprintf :message="$options.i18n.USAGE_QUOTAS_SUBTITLE">
        <template #namespaceName>
          <strong>
            {{ namespaceName }}
          </strong>
        </template>
      </gl-sprintf>
    </p>
    <gl-alert v-if="!tabs.length" variant="danger" :dismissible="false">
      {{ s__('UsageQuota|Something went wrong while loading Usage Quotas Tabs.') }}
    </gl-alert>
    <gl-tabs v-else>
      <gl-tab v-for="(tab, index) in tabs" :key="`${tab.title}_${index}`" :title="tab.title">
        <component :is="tab.component" :data-testid="`${tab.component}-tab`" />
      </gl-tab>
    </gl-tabs>
  </section>
</template>
