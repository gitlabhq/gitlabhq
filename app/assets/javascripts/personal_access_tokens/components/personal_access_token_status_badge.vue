<script>
import { GlBadge } from '@gitlab/ui';
import { s__ } from '~/locale';
import { isWithin2Weeks } from '~/vue_shared/access_tokens/utils';

export default {
  name: 'PersonalAccessTokenStatusBadge',
  components: {
    GlBadge,
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
    revoked: s__('AccessTokens|Revoked'),
    expired: s__('AccessTokens|Expired'),
    expiringSoon: s__('AccessTokens|Expiring soon'),
    expiringSoonTooltip: s__('AccessTokens|Token expires in less than two weeks.'),
  },
};
</script>

<template>
  <div>
    <gl-badge v-if="isTokenRevoked" icon="remove" variant="danger">
      {{ $options.i18n.revoked }}
    </gl-badge>
    <gl-badge v-if="isTokenExpired" icon="time-out">
      {{ $options.i18n.expired }}
    </gl-badge>
    <gl-badge
      v-if="isTokenExpiringSoon"
      v-gl-tooltip.d0="$options.i18n.expiringSoonTooltip"
      icon="expire"
      variant="warning"
    >
      {{ $options.i18n.expiringSoon }}
    </gl-badge>
  </div>
</template>
