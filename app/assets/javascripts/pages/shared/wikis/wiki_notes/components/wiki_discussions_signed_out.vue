<script>
import { GlSprintf, GlLink } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'WikiDiscussionsSignedOut',
  components: {
    GlSprintf,
    GlLink,
  },
  inject: ['registerPath', 'signInPath'],
  props: {
    isReply: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    signedOutText() {
      return this.isReply
        ? __(
            'Please %{registerLinkStart}register%{registerLinkEnd} or %{signInLinkStart}sign in%{signInLinkEnd} to reply.',
          )
        : __(
            'Please %{registerLinkStart}register%{registerLinkEnd} or %{signInLinkStart}sign in%{signInLinkEnd} to add a comment.',
          );
    },
  },
};
</script>

<template>
  <div class="disabled-comment gl-text-center gl-text-secondary">
    <gl-sprintf :message="signedOutText">
      <template #registerLink="{ content }">
        <gl-link :href="registerPath">{{ content }}</gl-link>
      </template>
      <template #signInLink="{ content }">
        <gl-link :href="signInPath">{{ content }}</gl-link>
      </template>
    </gl-sprintf>
  </div>
</template>
