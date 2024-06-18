<script>
import { GlModal, GlSprintf, GlLink, GlButton } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { glEmojiTag } from '~/emoji';
import { s__, sprintf } from '~/locale';
import Tracking from '~/tracking';
import { getHideAlertModalCookie, setHideAlertModalCookie } from '../utils';
import {
  UPGRADE_DOCS_URL,
  ABOUT_RELEASES_PAGE,
  ALERT_MODAL_ID,
  TRACKING_ACTIONS,
  TRACKING_LABELS,
} from '../constants';

export default {
  name: 'SecurityPatchUpgradeAlertModal',
  i18n: {
    modalTitle: s__('VersionCheck|Important notice - Critical patch release'),
    modalBodyNoStableVersions: s__(
      'VersionCheck|You are currently on version %{currentVersion}! We strongly recommend upgrading your GitLab installation immediately.',
    ),
    modalBodyStableVersions: s__(
      'VersionCheck|You are currently on version %{currentVersion}! We strongly recommend upgrading your GitLab installation to one of the following versions immediately: %{latestStableVersions}.',
    ),
    additionalAvailablePatch: s__(
      'VersionCheck|Additionally, there is an available stable patch for your current GitLab minor version: %{latestStableVersionOfMinor}',
    ),
    modalDetails: s__('VersionCheck|%{details}'),
    learnMore: s__('VersionCheck|Learn more about this critical patch release.'),
    primaryButtonText: s__('VersionCheck|Upgrade now'),
    secondaryButtonText: s__('VersionCheck|Remind me again in 3 days'),
  },
  components: {
    GlModal,
    GlSprintf,
    GlLink,
    GlButton,
  },
  directives: {
    SafeHtml,
  },
  mixins: [Tracking.mixin()],
  props: {
    currentVersion: {
      type: String,
      required: true,
    },
    details: {
      type: String,
      required: false,
      default: '',
    },
    latestStableVersions: {
      type: Array,
      required: false,
      default: () => [],
    },
    latestStableVersionOfMinor: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      visible: true,
    };
  },
  computed: {
    alertEmoji() {
      return glEmojiTag('rotating_light');
    },
    modalBody() {
      if (this.latestStableVersions?.length > 0) {
        return this.$options.i18n.modalBodyStableVersions;
      }

      return this.$options.i18n.modalBodyNoStableVersions;
    },
    modalDetails() {
      return sprintf(this.$options.i18n.modalDetails, { details: this.details });
    },
    latestStableVersionsStrings() {
      return this.latestStableVersions?.length > 0 ? this.latestStableVersions.join(', ') : '';
    },
    showLatestStableVersionOfMinor() {
      return (
        this.latestStableVersionOfMinor &&
        !this.latestStableVersionsStrings.includes(this.latestStableVersionOfMinor)
      );
    },
  },
  created() {
    if (getHideAlertModalCookie(this.currentVersion)) {
      this.visible = false;
      return;
    }

    this.dispatchTrackingEvent(TRACKING_ACTIONS.RENDER, TRACKING_LABELS.MODAL);
  },
  methods: {
    dispatchTrackingEvent(action, label) {
      this.track(action, {
        label,
        property: this.currentVersion,
      });
    },
    trackLearnMoreClick() {
      this.dispatchTrackingEvent(TRACKING_ACTIONS.CLICK_LINK, TRACKING_LABELS.LEARN_MORE_LINK);
    },
    trackRemindMeLaterClick() {
      this.dispatchTrackingEvent(TRACKING_ACTIONS.CLICK_BUTTON, TRACKING_LABELS.REMIND_ME_BTN);
      setHideAlertModalCookie(this.currentVersion);
      this.$refs.alertModal.hide();
    },
    trackUpgradeNowClick() {
      this.dispatchTrackingEvent(TRACKING_ACTIONS.CLICK_LINK, TRACKING_LABELS.UPGRADE_BTN_LINK);
      setHideAlertModalCookie(this.currentVersion);
    },
    trackModalDismissed() {
      this.dispatchTrackingEvent(TRACKING_ACTIONS.CLICK_BUTTON, TRACKING_LABELS.DISMISS);
    },
  },
  safeHtmlConfig: { ADD_TAGS: ['gl-emoji'] },
  UPGRADE_DOCS_URL,
  ABOUT_RELEASES_PAGE,
  ALERT_MODAL_ID,
};
</script>

<template>
  <gl-modal
    ref="alertModal"
    :modal-id="$options.ALERT_MODAL_ID"
    :visible="visible"
    @close="trackModalDismissed"
  >
    <template #modal-title>
      <span v-safe-html:[$options.safeHtmlConfig]="alertEmoji"></span>
      <span data-testid="alert-modal-title">{{ $options.i18n.modalTitle }}</span>
    </template>
    <template #default>
      <div data-testid="alert-modal-body" class="gl-mb-6">
        <gl-sprintf :message="modalBody">
          <template #currentVersion>
            <span class="gl-font-bold">{{ currentVersion }}</span>
          </template>
          <template #latestStableVersions>
            <span class="gl-font-bold">{{ latestStableVersionsStrings }}</span>
          </template>
        </gl-sprintf>
        <div v-if="showLatestStableVersionOfMinor" class="gl-mt-6">
          <gl-sprintf :message="$options.i18n.additionalAvailablePatch">
            <template #latestStableVersionOfMinor>
              <span class="gl-font-bold">{{ latestStableVersionOfMinor }}</span>
            </template>
          </gl-sprintf>
        </div>
      </div>
      <div v-if="details" data-testid="alert-modal-details" class="gl-mb-6">
        {{ modalDetails }}
      </div>
      <gl-link :href="$options.ABOUT_RELEASES_PAGE" @click="trackLearnMoreClick">{{
        $options.i18n.learnMore
      }}</gl-link>
    </template>
    <template #modal-footer>
      <gl-button data-testid="alert-modal-remind-button" @click="trackRemindMeLaterClick">{{
        $options.i18n.secondaryButtonText
      }}</gl-button>
      <gl-button
        data-testid="alert-modal-upgrade-button"
        :href="$options.UPGRADE_DOCS_URL"
        variant="confirm"
        @click="trackUpgradeNowClick"
        >{{ $options.i18n.primaryButtonText }}</gl-button
      >
    </template>
  </gl-modal>
</template>
