<script>
import { GlDrawer, GlSprintf, GlButton, GlIcon, GlAlert } from '@gitlab/ui';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { localeDateFormat } from '~/lib/utils/datetime_utility';
import { isWithin2Weeks } from '../../utils';
import DateWithTooltip from './date_with_tooltip.vue';

export default {
  name: 'DetailsDrawer',
  components: { GlDrawer, GlSprintf, GlButton, GlIcon, GlAlert, DateWithTooltip },
  props: {
    token: {
      type: Object,
      required: false,
      default: null,
    },
  },
  computed: {
    createdDateString() {
      return localeDateFormat.asDateTimeFull.format(new Date(this.token.createdAt));
    },
    isExpired() {
      return !this.token.active && !this.token.revoked;
    },
    isExpiringSoon() {
      return this.token.active && this.token.expiresAt
        ? isWithin2Weeks(this.token.expiresAt)
        : false;
    },
  },
  getContentWrapperHeight,
  DRAWER_Z_INDEX,
};
</script>

<template>
  <gl-drawer
    :header-height="$options.getContentWrapperHeight()"
    :z-index="$options.DRAWER_Z_INDEX"
    :open="Boolean(token)"
    @close="$emit('close')"
  >
    <template v-if="token" #title>
      <h2 class="gl-heading-3 gl-my-0 gl-line-clamp-1 gl-text-size-h2">
        <gl-sprintf :message="s__(`AccessTokens|Details for '%{name}'`)">
          <template #name>{{ token.name }}</template>
        </gl-sprintf>
      </h2>
    </template>

    <template v-if="token" #header>
      <div v-if="token.active" class="gl-mt-3 gl-flex gl-gap-3">
        <gl-button @click="$emit('rotate', token)">
          {{ s__('AccessTokens|Rotate') }}
        </gl-button>
        <gl-button variant="danger" category="secondary" @click="$emit('revoke', token)">
          {{ s__('AccessTokens|Revoke') }}
        </gl-button>
      </div>

      <gl-alert v-if="token.revoked" class="gl-mt-3" :dismissible="false">
        {{ s__('AccessTokens|This token was revoked.') }}
      </gl-alert>
      <gl-alert v-if="isExpired" class="gl-mt-3" :dismissible="false">
        {{ s__('AccessTokens|This token has expired.') }}
      </gl-alert>
      <gl-alert v-if="isExpiringSoon" class="gl-mt-3" variant="warning" :dismissible="false">{{
        s__(
          'AccessTokens|This token expires soon. If still needed, generate a new token with the same settings.',
        )
      }}</gl-alert>
    </template>

    <template v-if="token">
      <dl class="gl-mb-0 [&>dd]:gl-mb-4 [&>dt]:gl-mb-2">
        <dt>{{ s__('AccessTokens|Name') }}</dt>
        <dd class="gl-wrap-anywhere">{{ token.name }}</dd>

        <dt>{{ s__('AccessTokens|Description') }}</dt>
        <dd class="gl-wrap-anywhere">
          <template v-if="token.description">{{ token.description }}</template>
          <span v-else class="gl-text-subtle">
            {{ s__('AccessTokens|No description provided.') }}
          </span>
        </dd>

        <dt><gl-icon name="expire" /> {{ s__('AccessTokens|Expires') }}</dt>
        <dd><date-with-tooltip :timestamp="token.expiresAt" :token="token" /></dd>

        <dt><gl-icon name="hourglass" /> {{ s__('AccessTokens|Last used') }}</dt>
        <dd><date-with-tooltip :timestamp="token.lastUsedAt" /></dd>

        <dt>{{ s__('AccessTokens|IP Usage') }}</dt>
        <dd v-if="token.lastUsedIps.length">
          <div v-for="ip in token.lastUsedIps" :key="ip">{{ ip }}</div>
        </dd>
        <dd v-else>{{ __('None') }}</dd>

        <dt>{{ s__('AccessTokens|Token scope') }}</dt>
        <dd>
          <div v-for="scope in token.scopes" :key="scope" class="gl-mb-2">
            <gl-icon name="check-sm" variant="success" class="gl-mr-2" /> {{ scope }}
          </div>
        </dd>
      </dl>

      <hr class="gl-mx-5 gl-mb-3 gl-mt-0 gl-border-neutral-100 !gl-py-0" />

      <dl class="[&>dd]:gl-mb-4 [&>dt]:gl-mb-2">
        <dt>{{ __('Type') }}</dt>
        <dd>{{ s__('AccessTokens|Legacy token') }}</dd>

        <dt><gl-icon name="clock" /> {{ s__('AccessTokens|Created') }}</dt>
        <dd>{{ createdDateString }}</dd>
      </dl>
    </template>
  </gl-drawer>
</template>
