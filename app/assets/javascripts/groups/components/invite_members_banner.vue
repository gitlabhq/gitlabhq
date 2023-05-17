<script>
import { GlBanner } from '@gitlab/ui';
import eventHub from '~/invite_members/event_hub';
import axios from '~/lib/utils/axios_utils';
import { s__ } from '~/locale';
import Tracking from '~/tracking';

const trackingMixin = Tracking.mixin();

export default {
  components: {
    GlBanner,
  },
  mixins: [trackingMixin],
  inject: ['svgPath', 'trackLabel', 'calloutsPath', 'calloutsFeatureId', 'groupId'],
  data() {
    return {
      isDismissed: false,
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
      axios
        .post(this.calloutsPath, {
          feature_name: this.calloutsFeatureId,
          group_id: this.groupId,
        })
        .catch((e) => {
          // eslint-disable-next-line @gitlab/require-i18n-strings, no-console
          console.error('Failed to dismiss banner.', e);
        });

      this.isDismissed = true;
      this.track(this.$options.dismissEvent);
    },
    trackOnShow() {
      this.$nextTick(() => {
        if (!this.isDismissed) this.track(this.$options.displayEvent);
      });
    },
    openModal() {
      eventHub.$emit('openModal', { source: this.$options.openModalSource });
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
  openModalSource: 'invite_members_banner',
  dismissEvent: 'invite_members_banner_dismissed',
};
</script>

<template>
  <gl-banner
    v-if="!isDismissed"
    ref="banner"
    data-testid="invite-members-banner"
    :title="$options.i18n.title"
    :button-text="$options.i18n.button_text"
    :svg-path="svgPath"
    @close="handleClose"
    @primary="openModal"
  >
    <p>{{ $options.i18n.body }}</p>
  </gl-banner>
</template>
