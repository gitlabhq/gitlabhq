<script>
import { GlAlert } from '@gitlab/ui';
import { s__ } from '~/locale';
import { isWithin2Weeks } from '~/vue_shared/access_tokens/utils';

export default {
  name: 'PersonalAccessTokenStatusAlert',
  components: {
    GlAlert,
  },
  props: {
    token: {
      type: Object,
      required: true,
    },
  },
  computed: {
    isTokenRevoked() {
      return this.token.revoked;
    },
    isTokenExpired() {
      return !this.token.active && !this.token.revoked;
    },
    isTokenExpiringSoon() {
      if (this.token.expiresAt) {
        return this.token.active && isWithin2Weeks(this.token.expiresAt);
      }

      return false;
    },
  },
  i18n: {
    revoked: s__('AccessTokens|This token was revoked.'),
    expired: s__('AccessTokens|This token has expired.'),
    expiringSoon: s__(
      'AccessTokens|This token expires soon. If still needed, generate a new token with the same settings.',
    ),
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="isTokenRevoked" :dismissible="false">
      {{ $options.i18n.revoked }}
    </gl-alert>
    <gl-alert v-if="isTokenExpired" :dismissible="false">
      {{ $options.i18n.expired }}
    </gl-alert>
    <gl-alert v-if="isTokenExpiringSoon" variant="warning" :dismissible="false">
      {{ $options.i18n.expiringSoon }}
    </gl-alert>
  </div>
</template>
