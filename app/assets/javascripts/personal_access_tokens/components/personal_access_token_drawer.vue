<script>
import { GlDrawer, GlSprintf, GlIcon, GlTooltipDirective, GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { timeFormattedAsDate, timeFormattedAsDateFull } from '../utils';
import PersonalAccessTokenStatusAlert from './personal_access_token_status_alert.vue';
import PersonalAccessTokenStatusBadge from './personal_access_token_status_badge.vue';
import PersonalAccessTokenGranularScopes from './personal_access_token_granular_scopes.vue';
import PersonalAccessTokenLegacyScopes from './personal_access_token_legacy_scopes.vue';

export default {
  name: 'PersonalAccessTokenDrawer',
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlDrawer,
    GlSprintf,
    GlIcon,
    GlButton,
    PersonalAccessTokenStatusAlert,
    PersonalAccessTokenStatusBadge,
    PersonalAccessTokenGranularScopes,
    PersonalAccessTokenLegacyScopes,
  },
  props: {
    token: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  emits: ['close', 'rotate', 'revoke'],
  computed: {
    isTokenActive() {
      return this.token?.active;
    },
    isTokenGranular() {
      return this.token?.granular;
    },
    expiryDate() {
      return timeFormattedAsDate(this.token.expiresAt);
    },
    expiryTimestamp() {
      return timeFormattedAsDateFull(this.token.expiresAt);
    },
    lastUsedDate() {
      return timeFormattedAsDate(this.token.lastUsedAt);
    },
    lastUsedTimestamp() {
      return timeFormattedAsDateFull(this.token.lastUsedAt);
    },
    createdTimestamp() {
      return timeFormattedAsDateFull(this.token.createdAt);
    },
  },
  methods: {
    handleRotate() {
      this.$emit('rotate', this.token);
    },
    handleRevoke() {
      this.$emit('revoke', this.token);
    },
  },
  i18n: {
    title: s__(`AccessTokens|Details for '%{name}'`),
    name: s__('AccessTokens|Name'),
    description: s__('AccessTokens|Description'),
    noDescription: s__('AccessTokens|No description provided.'),
    rotate: s__('AccessTokens|Rotate'),
    revoke: s__('AccessTokens|Revoke'),
    expires: s__('AccessTokens|Expires'),
    lastUsed: s__('AccessTokens|Last used'),
    ipUsage: s__('AccessTokens|IP Usage'),
    type: s__('AccessTokens|Type'),
    legacyToken: s__('AccessTokens|Legacy token'),
    fineGrainedToken: s__('AccessTokens|Fine-grained token'),
    created: s__('AccessTokens|Created'),
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
        <gl-sprintf :message="$options.i18n.title">
          <template #name>{{ token.name }}</template>
        </gl-sprintf>
      </h2>
    </template>

    <template v-if="token" #header>
      <div v-if="isTokenActive" class="gl-mt-3 gl-flex gl-gap-3">
        <gl-button data-testid="rotate-token" @click="handleRotate">
          {{ $options.i18n.rotate }}
        </gl-button>
        <gl-button
          variant="danger"
          category="secondary"
          data-testid="revoke-token"
          @click="handleRevoke"
        >
          {{ $options.i18n.revoke }}
        </gl-button>
      </div>

      <personal-access-token-status-alert :token="token" class="gl-mt-3" />
    </template>

    <template v-if="token">
      <div>
        <div class="gl-font-bold">{{ $options.i18n.name }}</div>
        <div class="gl-mt-2 gl-wrap-anywhere">{{ token.name }}</div>

        <div class="gl-mt-5 gl-font-bold">{{ $options.i18n.description }}</div>
        <div v-if="token.description" class="gl-mt-2 gl-wrap-anywhere">{{ token.description }}</div>
        <div v-else>{{ $options.i18n.noDescription }}</div>

        <div class="gl-mt-5 gl-font-bold">
          <gl-icon name="expire" class="gl-mr-2" />
          {{ $options.i18n.expires }}
        </div>
        <div class="gl-mt-2 gl-flex gl-flex-wrap gl-items-center">
          <div class="gl-mr-2">
            <span v-gl-tooltip="expiryTimestamp">
              {{ expiryDate }}
            </span>
          </div>
          <personal-access-token-status-badge :token="token" />
        </div>

        <div class="gl-mt-5 gl-font-bold">
          <gl-icon name="hourglass" class="gl-mr-2" />
          {{ $options.i18n.lastUsed }}
        </div>
        <div class="gl-mt-2">
          <span v-gl-tooltip="lastUsedTimestamp">
            {{ lastUsedDate }}
          </span>
        </div>

        <template v-if="token.lastUsedIps.length">
          <div class="gl-mt-5 gl-font-bold">
            {{ $options.i18n.ipUsage }}
          </div>
          <div class="gl-mt-2">
            <div v-for="(ip, index) in token.lastUsedIps" :key="index">
              {{ ip }}
            </div>
          </div>
        </template>
      </div>

      <hr class="!gl-my-0 gl-mx-5 !gl-p-0" />

      <div>
        <personal-access-token-granular-scopes v-if="isTokenGranular" :scopes="token.scopes" />
        <personal-access-token-legacy-scopes v-else :scopes="token.scopes" />
      </div>

      <hr class="!gl-my-0 gl-mx-5 !gl-p-0" />

      <div>
        <div class="gl-font-bold">{{ $options.i18n.type }}</div>
        <div v-if="isTokenGranular" class="gl-mt-2">{{ $options.i18n.fineGrainedToken }}</div>
        <div v-else class="gl-mt-2">{{ $options.i18n.legacyToken }}</div>

        <div class="gl-mt-4 gl-font-bold">
          <gl-icon name="clock" class="gl-mr-2" />
          {{ $options.i18n.created }}
        </div>
        <div class="gl-mt-2">{{ createdTimestamp }}</div>
      </div>
    </template>
  </gl-drawer>
</template>
