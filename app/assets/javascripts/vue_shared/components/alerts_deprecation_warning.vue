<script>
import { GlAlert, GlLink, GlSprintf } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';

export default {
  components: {
    GlAlert,
    GlLink,
    GlSprintf,
  },
  inject: ['hasManagedPrometheus'],
  i18n: {
    alertsDeprecationText: s__(
      'Metrics|GitLab-managed Prometheus is deprecated and %{linkStart}scheduled for removal%{linkEnd}. Following this removal, your existing alerts will continue to function as part of the new cluster integration. However, you will no longer be able to add new alerts or edit existing alerts from the metrics dashboard.',
    ),
  },
  methods: {
    helpPagePath,
  },
};
</script>

<template>
  <gl-alert
    v-if="hasManagedPrometheus"
    variant="warning"
    class="my-2"
    data-testid="alerts-deprecation-warning"
  >
    <gl-sprintf :message="$options.i18n.alertsDeprecationText">
      <template #link="{ content }">
        <gl-link
          :href="
            helpPagePath('operations/metrics/alerts.html', {
              anchor: 'managed-prometheus-instances',
            })
          "
          target="_blank"
        >
          <span>{{ content }}</span>
        </gl-link>
      </template>
    </gl-sprintf>
  </gl-alert>
</template>
