<script>
import { GlAlert, GlSprintf, GlLink, GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import { UPGRADE_DOCS_URL, ABOUT_RELEASES_PAGE } from '../constants';

export default {
  name: 'SecurityPatchUpgradeAlert',
  i18n: {
    alertTitle: s__('VersionCheck|Critical security upgrade available'),
    alertBody: s__(
      'VersionCheck|You are currently on version %{currentVersion}. We strongly recommend upgrading your GitLab installation. %{link}',
    ),
    learnMore: s__('VersionCheck|Learn more about this critical security release.'),
    primaryButtonText: s__('VersionCheck|Upgrade now'),
  },
  components: {
    GlAlert,
    GlSprintf,
    GlLink,
    GlButton,
  },
  mixins: [Tracking.mixin()],
  props: {
    currentVersion: {
      type: String,
      required: true,
    },
  },
  mounted() {
    this.track('render', {
      label: 'security_patch_upgrade_alert',
      property: this.currentVersion,
    });
  },
  methods: {
    trackLearnMoreClick() {
      this.track('click_link', {
        label: 'security_patch_upgrade_alert_learn_more',
        property: this.currentVersion,
      });
    },
    trackUpgradeNowClick() {
      this.track('click_link', {
        label: 'security_patch_upgrade_alert_upgrade_now',
        property: this.currentVersion,
      });
    },
  },
  UPGRADE_DOCS_URL,
  ABOUT_RELEASES_PAGE,
};
</script>

<template>
  <gl-alert :title="$options.i18n.alertTitle" variant="danger" :dismissible="false">
    <gl-sprintf :message="$options.i18n.alertBody">
      <template #currentVersion>
        <span class="gl-font-weight-bold">{{ currentVersion }}</span>
      </template>
      <template #link>
        <gl-link :href="$options.ABOUT_RELEASES_PAGE" @click="trackLearnMoreClick">{{
          $options.i18n.learnMore
        }}</gl-link>
      </template>
    </gl-sprintf>
    <template #actions>
      <gl-button
        :href="$options.UPGRADE_DOCS_URL"
        variant="confirm"
        @click="trackUpgradeNowClick"
        >{{ $options.i18n.primaryButtonText }}</gl-button
      >
    </template>
  </gl-alert>
</template>
