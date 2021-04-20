<script>
import { GlEmptyState, GlButton, GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';
import alertsHelpUrlQuery from '../graphql/queries/alert_help_url.query.graphql';

export default {
  i18n: {
    emptyState: {
      title: s__('AlertManagement|Surface alerts in GitLab'),
      info: s__(
        'AlertManagement|Display alerts from all your monitoring tools directly within GitLab. Streamline the investigation of your alerts and the escalation of alerts to incidents.',
      ),
      buttonText: s__('AlertManagement|Authorize external service'),
    },
    moreInformation: s__('AlertManagement|More information'),
  },
  components: {
    GlEmptyState,
    GlButton,
    GlLink,
  },
  apollo: {
    alertsHelpUrl: {
      query: alertsHelpUrlQuery,
    },
  },
  inject: ['enableAlertManagementPath', 'userCanEnableAlertManagement', 'emptyAlertSvgPath'],
  data() {
    return {
      alertsHelpUrl: '',
    };
  },
};
</script>
<template>
  <div>
    <gl-empty-state :title="$options.i18n.emptyState.title" :svg-path="emptyAlertSvgPath">
      <template #description>
        <div class="gl-display-block">
          <span>{{ $options.i18n.emptyState.info }}</span>
          <gl-link :href="alertsHelpUrl" target="_blank">
            {{ $options.i18n.moreInformation }}
          </gl-link>
        </div>
        <div v-if="userCanEnableAlertManagement" class="gl-display-block center gl-pt-4">
          <gl-button category="primary" variant="confirm" :href="enableAlertManagementPath">
            {{ $options.i18n.emptyState.buttonText }}
          </gl-button>
        </div>
      </template>
    </gl-empty-state>
  </div>
</template>
