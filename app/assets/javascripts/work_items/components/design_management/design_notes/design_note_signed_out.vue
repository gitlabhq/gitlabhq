<script>
import { GlSprintf, GlLink } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlSprintf,
    GlLink,
  },
  props: {
    registerPath: {
      type: String,
      required: true,
    },
    signInPath: {
      type: String,
      required: true,
    },
    isAddDiscussion: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    signedOutText() {
      return this.isAddDiscussion
        ? __(
            'Please %{registerLinkStart}register%{registerLinkEnd} or %{signInLinkStart}sign in%{signInLinkEnd} to start a new discussion.',
          )
        : __(
            'Please %{registerLinkStart}register%{registerLinkEnd} or %{signInLinkStart}sign in%{signInLinkEnd} to reply.',
          );
    },
  },
};
</script>

<template>
  <div class="disabled-comment !gl-border-none gl-text-center gl-text-subtle">
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
