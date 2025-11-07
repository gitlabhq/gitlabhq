<script>
import { GlTooltipDirective, GlIcon, GlBadge } from '@gitlab/ui';
import { localeDateFormat } from '~/lib/utils/datetime_utility';
import { __ } from '~/locale';
import { fifteenDaysFromNow } from '~/vue_shared/access_tokens/utils';

export default {
  name: 'DateWithTooltip',
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: { GlIcon, GlBadge },
  props: {
    timestamp: {
      type: String,
      required: false,
      default: null,
    },
    icon: {
      type: String,
      required: false,
      default: null,
    },
    token: {
      type: Object,
      required: false,
      default: null,
    },
  },
  computed: {
    timestampDate() {
      // We can't use newDate() from datetime_utility.js because it will treat timestamps that only
      // have a date but no time or timezone as a local date, but we need to treat it as a UTC date.
      return this.timestamp ? new Date(this.timestamp) : null;
    },
    dateString() {
      return this.timestampDate ? localeDateFormat.asDate.format(this.timestampDate) : __('Never');
    },
    dateTimeString() {
      return this.timestampDate ? localeDateFormat.asDateTimeFull.format(this.timestampDate) : null;
    },
    isTokenExpired() {
      return !this.token.active && !this.token.revoked;
    },
    isTokenExpiringSoon() {
      return this.token.active && this.token.expiresAt < fifteenDaysFromNow();
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-items-center gl-gap-3">
    <span v-gl-tooltip.d0="dateTimeString" class="gl-whitespace-nowrap">
      <gl-icon v-if="icon" :name="icon" class="gl-mr-2" />
      <slot :date="dateString">{{ dateString }}</slot>
    </span>

    <template v-if="token">
      <gl-badge v-if="token.revoked" icon="remove" variant="danger">
        {{ __('Revoked') }}
      </gl-badge>
      <gl-badge v-if="isTokenExpired" icon="time-out">
        {{ __('Expired') }}
      </gl-badge>
      <gl-badge
        v-if="isTokenExpiringSoon"
        v-gl-tooltip.d0="s__('AccessTokens|Token expires in less than two weeks.')"
        icon="expire"
        variant="warning"
      >
        {{ __('Expiring soon') }}
      </gl-badge>
    </template>
  </div>
</template>
