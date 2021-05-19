<script>
import { GlBanner } from '@gitlab/ui';
import eventHub from '~/invite_members/event_hub';
import { parseBoolean, setCookie, getCookie } from '~/lib/utils/common_utils';
import { s__ } from '~/locale';
import Tracking from '~/tracking';

const trackingMixin = Tracking.mixin();

export default {
  components: {
    GlBanner,
  },
  mixins: [trackingMixin],
  inject: ['svgPath', 'isDismissedKey', 'trackLabel'],
  data() {
    return {
      isDismissed: parseBoolean(getCookie(this.isDismissedKey)),
      tracking: {
        label: this.trackLabel,
      },
    };
  },
  mounted() {
    this.trackOnShow();
  },
  methods: {
    handleClose() {
      setCookie(this.isDismissedKey, true);
      this.isDismissed = true;
      this.track(this.$options.dismissEvent);
    },
    trackOnShow() {
      this.$nextTick(() => {
        if (!this.isDismissed) this.track(this.$options.displayEvent);
      });
    },
    openModal() {
      eventHub.$emit('openModal', {
        inviteeType: 'members',
        source: this.$options.openModalSource,
      });
      this.track(this.$options.buttonClickEvent);
    },
  },
  i18n: {
    title: s__('InviteMembersBanner|Collaborate with your team'),
    body: s__(
      "InviteMembersBanner|We noticed that you haven't invited anyone to this group. Invite your colleagues so you can discuss issues, collaborate on merge requests, and share your knowledge.",
    ),
    button_text: s__('InviteMembersBanner|Invite your colleagues'),
  },
  displayEvent: 'invite_members_banner_displayed',
  buttonClickEvent: 'invite_members_banner_button_clicked',
  openModalSource: 'invite_members_banner',
  dismissEvent: 'invite_members_banner_dismissed',
};
</script>

<template>
  <gl-banner
    v-if="!isDismissed"
    ref="banner"
    :title="$options.i18n.title"
    :button-text="$options.i18n.button_text"
    :svg-path="svgPath"
    @close="handleClose"
    @primary="openModal"
  >
    <p>{{ $options.i18n.body }}</p>
  </gl-banner>
</template>
