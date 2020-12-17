<script>
import { GlSprintf, GlTooltipDirective } from '@gitlab/ui';
import {
  approximateDuration,
  differenceInSeconds,
  formatDate,
  getDayDifference,
} from '~/lib/utils/datetime_utility';
import { DAYS_TO_EXPIRE_SOON } from '../../constants';

export default {
  name: 'ExpiresAt',
  components: { GlSprintf },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    date: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    noExpirationSet() {
      return this.date === null;
    },
    parsed() {
      return new Date(this.date);
    },
    differenceInSeconds() {
      return differenceInSeconds(new Date(), this.parsed);
    },
    isExpired() {
      return this.differenceInSeconds <= 0;
    },
    inWords() {
      return approximateDuration(this.differenceInSeconds);
    },
    formatted() {
      return formatDate(this.parsed);
    },
    expiresSoon() {
      return getDayDifference(new Date(), this.parsed) < DAYS_TO_EXPIRE_SOON;
    },
    cssClass() {
      return {
        'gl-text-red-500': this.isExpired,
        'gl-text-orange-500': this.expiresSoon,
      };
    },
  },
};
</script>

<template>
  <span v-if="noExpirationSet">{{ s__('Members|No expiration set') }}</span>
  <span v-else v-gl-tooltip.hover :title="formatted" :class="cssClass">
    <template v-if="isExpired">{{ s__('Members|Expired') }}</template>
    <gl-sprintf v-else :message="s__('Members|in %{time}')">
      <template #time>
        {{ inWords }}
      </template>
    </gl-sprintf>
  </span>
</template>
