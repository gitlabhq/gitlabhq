<script>
import { GlAlert, GlSprintf, GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

const COMPATIBILITY_ALERT_STATE_KEY = 'compatibility_alert_dismissed';

export default {
  name: 'CompatibilityAlert',
  components: {
    GlAlert,
    GlSprintf,
    GlLink,
    LocalStorageSync,
  },
  mixins: [glFeatureFlagMixin()],
  data() {
    return {
      alertDismissed: false,
    };
  },
  computed: {
    shouldShowAlert() {
      return !this.alertDismissed;
    },
    isOauthSelfManagedEnabled() {
      return this.glFeatures.jiraConnectOauth && this.glFeatures.jiraConnectOauthSelfManaged;
    },
    alertBody() {
      return this.isOauthSelfManagedEnabled
        ? this.$options.i18n.body
        : this.$options.i18n.bodyDotCom;
    },
  },
  methods: {
    dismissAlert() {
      this.alertDismissed = true;
    },
  },
  i18n: {
    title: s__('Integrations|Known limitations'),
    body: s__(
      'Integrations|Adding a namespace only works in browsers that allow cross-site cookies. %{linkStart}Learn more%{linkEnd}.',
    ),
    bodyDotCom: s__(
      'Integrations|This integration only works with GitLab.com. Adding a namespace only works in browsers that allow cross-site cookies. %{linkStart}Learn more%{linkEnd}.',
    ),
  },
  DOCS_LINK_URL: helpPagePath('integration/jira/connect-app'),
  COMPATIBILITY_ALERT_STATE_KEY,
};
</script>
<template>
  <local-storage-sync
    v-model="alertDismissed"
    :storage-key="$options.COMPATIBILITY_ALERT_STATE_KEY"
  >
    <gl-alert
      v-if="shouldShowAlert"
      variant="info"
      :title="$options.i18n.title"
      @dismiss="dismissAlert"
    >
      <gl-sprintf :message="alertBody">
        <template #link="{ content }">
          <gl-link :href="$options.DOCS_LINK_URL" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </gl-alert>
  </local-storage-sync>
</template>
