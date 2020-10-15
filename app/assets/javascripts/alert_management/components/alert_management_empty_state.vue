<script>
import { GlEmptyState, GlButton, GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';
import alertsHelpUrlQuery from '../graphql/queries/alert_help_url.query.graphql';

export default {
  i18n: {
    emptyState: {
      opsgenie: {
        title: s__('AlertManagement|Opsgenie is enabled'),
        info: s__(
          'AlertManagement|You have enabled the Opsgenie integration. Your alerts will be visible directly in Opsgenie.',
        ),
        buttonText: s__('AlertManagement|View alerts in Opsgenie'),
      },
      gitlab: {
        title: s__('AlertManagement|Surface alerts in GitLab'),
        info: s__(
          'AlertManagement|Display alerts from all your monitoring tools directly within GitLab. Streamline the investigation of your alerts and the escalation of alerts to incidents.',
        ),
        buttonText: s__('AlertManagement|Authorize external service'),
      },
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
  inject: [
    'enableAlertManagementPath',
    'userCanEnableAlertManagement',
    'emptyAlertSvgPath',
    'opsgenieMvcEnabled',
    'opsgenieMvcTargetUrl',
  ],
  data() {
    return {
      alertsHelpUrl: '',
    };
  },
  computed: {
    emptyState() {
      return {
        ...(this.opsgenieMvcEnabled
          ? this.$options.i18n.emptyState.opsgenie
          : this.$options.i18n.emptyState.gitlab),
        link: this.opsgenieMvcEnabled ? this.opsgenieMvcTargetUrl : this.enableAlertManagementPath,
      };
    },
    alertsCanBeEnabled() {
      return this.userCanEnableAlertManagement || this.opsgenieMvcEnabled;
    },
  },
};
</script>
<template>
  <div>
    <gl-empty-state :title="emptyState.title" :svg-path="emptyAlertSvgPath">
      <template #description>
        <div class="gl-display-block">
          <span>{{ emptyState.info }}</span>
          <gl-link v-if="!opsgenieMvcEnabled" :href="alertsHelpUrl" target="_blank">
            {{ $options.i18n.moreInformation }}
          </gl-link>
        </div>
        <div v-if="alertsCanBeEnabled" class="gl-display-block center gl-pt-4">
          <gl-button category="primary" variant="success" :href="emptyState.link">
            {{ emptyState.buttonText }}
          </gl-button>
        </div>
      </template>
    </gl-empty-state>
  </div>
</template>
