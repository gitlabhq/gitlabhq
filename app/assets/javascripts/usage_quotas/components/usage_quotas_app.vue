<script>
import { GlSprintf, GlTab, GlTabs } from '@gitlab/ui';
import { USAGE_QUOTAS_TITLE, USAGE_QUOTAS_SUBTITLE } from '../constants';

export default {
  name: 'UsageQuotasApp',
  components: { GlSprintf, GlTab, GlTabs },
  inject: ['namespaceName'],
  computed: {
    placeholder() {
      return `storage_app_placeholder`;
    },
  },
  USAGE_QUOTAS_TITLE,
  USAGE_QUOTAS_SUBTITLE,
};
</script>

<template>
  <section>
    <h1>{{ $options.USAGE_QUOTAS_TITLE }}</h1>
    <p data-testid="usage-quotas-page-subtitle">
      <gl-sprintf :message="$options.USAGE_QUOTAS_SUBTITLE">
        <template #namespaceName>
          <strong>
            {{ namespaceName }}
          </strong>
        </template>
      </gl-sprintf>
    </p>
    <gl-tabs>
      <gl-tab title="Storage"> {{ placeholder }} </gl-tab>
    </gl-tabs>
  </section>
</template>
