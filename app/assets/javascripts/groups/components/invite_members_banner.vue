<script>
import { GlBanner } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  components: {
    GlBanner,
  },
  inject: ['svgPath', 'inviteMembersPath'],
  data() {
    return {
      visible: true,
    };
  },
  methods: {
    handleClose() {
      this.visible = false;
    },
  },
  i18n: {
    title: s__('InviteMembersBanner|Collaborate with your team'),
    body: s__(
      "InviteMembersBanner|We noticed that you haven't invited anyone to this group. Invite your colleagues so you can discuss issues, collaborate on merge requests, and share your knowledge.",
    ),
    button_text: s__('InviteMembersBanner|Invite your colleagues'),
  },
};
</script>

<template>
  <gl-banner
    v-if="visible"
    ref="banner"
    :title="$options.i18n.title"
    :button-text="$options.i18n.button_text"
    :svg-path="svgPath"
    :button-link="inviteMembersPath"
    @close="handleClose"
  >
    <p>{{ $options.i18n.body }}</p>
  </gl-banner>
</template>
