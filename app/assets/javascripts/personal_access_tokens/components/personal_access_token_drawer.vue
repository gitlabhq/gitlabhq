<script>
import { GlIcon, GlTooltipDirective, GlButton, GlAttributeList } from '@gitlab/ui';
import { MountingPortal } from 'portal-vue';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import { s__, __, sprintf } from '~/locale';
import { timeFormattedAsDate, timeFormattedAsDateFull } from '../utils';
import PersonalAccessTokenStatusBadge from './personal_access_token_status_badge.vue';
import PersonalAccessTokenGranularScopes from './personal_access_token_granular_scopes.vue';
import PersonalAccessTokenLegacyScopes from './personal_access_token_legacy_scopes.vue';

export default {
  name: 'PersonalAccessTokenDrawer',
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    MountingPortal,
    CrudComponent,
    GlIcon,
    GlButton,
    GlAttributeList,
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
  emits: ['close', 'rotate', 'revoke', 'duplicate'],
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
    createdDate() {
      return timeFormattedAsDate(this.token.createdAt);
    },
    createdTimestamp() {
      return timeFormattedAsDateFull(this.token.createdAt);
    },
    createdOnText() {
      return sprintf(this.$options.i18n.created, {
        date: this.createdDate,
      });
    },
    attributesList() {
      return [
        {
          icon: 'token',
          label: this.$options.i18n.type,
          text: this.isTokenGranular
            ? this.$options.i18n.fineGrainedToken
            : this.$options.i18n.legacyToken,
        },
        {
          icon: 'text-description',
          label: this.$options.i18n.description,
          text: this.token.description || this.$options.i18n.noDescription,
        },
        { icon: 'expire', type: 'expiresAt', label: this.$options.i18n.expires, text: '' },
        { icon: 'history', type: 'lastUsedAt', label: this.$options.i18n.lastUsed, text: '' },
        { icon: 'earth', type: 'ipUsage', label: this.$options.i18n.ipUsage, text: '' },
      ];
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
    panelHeader: s__('AccessTokens|Personal access token detail'),
    description: s__('AccessTokens|Description'),
    noDescription: s__('AccessTokens|No description provided.'),
    rotate: s__('AccessTokens|Rotate'),
    revoke: s__('AccessTokens|Revoke'),
    duplicate: s__('AccessTokens|Duplicate'),
    expires: s__('AccessTokens|Expires'),
    lastUsed: s__('AccessTokens|Last used'),
    ipUsage: s__('AccessTokens|IP Usage'),
    noIpUsage: s__('AccessTokens|No IP activity recorded yet.'),
    type: s__('AccessTokens|Type'),
    legacyToken: s__('AccessTokens|Legacy token'),
    fineGrainedToken: s__('AccessTokens|Fine-grained token'),
    created: s__('AccessTokens|Created on %{date}'),
    scopes: s__('AccessTokens|Scopes'),
    closePanel: __('Close panel'),
  },
};
</script>

<template>
  <mounting-portal v-if="Boolean(token)" mount-to="#contextual-panel-portal" append>
    <div class="panel-content gl-h-full gl-pt-4 gl-leading-reset">
      <div class="gl-border-b gl-px-5 gl-pb-4">
        <div class="gl-flex gl-grow gl-items-center gl-justify-between">
          <span class="gl-text-sm gl-font-bold">{{ $options.i18n.panelHeader }}</span>
          <gl-button
            category="tertiary"
            icon="close"
            size="small"
            :title="$options.i18n.closePanel"
            @click="$emit('close')"
          />
        </div>
      </div>
      <div class="js-dynamic-panel-inner panel-content-inner !gl-px-5">
        <section>
          <div>
            <div class="gl-flex gl-items-center">
              <div>
                <h2 class="gl-heading-1 !gl-mt-5 gl-mb-2">
                  {{ token.name }}
                </h2>
                <div class="gl-flex gl-items-center gl-gap-2 gl-text-subtle">
                  <personal-access-token-status-badge :token="token" />
                  <span v-gl-tooltip="createdTimestamp" data-testid="token-created-on">
                    {{ createdOnText }}
                  </span>
                </div>
              </div>
              <div class="gl-ml-auto">
                <gl-button
                  v-if="isTokenGranular"
                  data-testid="duplicate-token"
                  @click="$emit('duplicate', token)"
                >
                  {{ $options.i18n.duplicate }}
                </gl-button>

                <template v-if="isTokenActive">
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
                </template>
              </div>
            </div>
          </div>

          <gl-attribute-list :items="attributesList" class="gl-mt-4" description-class="gl-ml-6">
            <template #description="{ item }">
              <template v-if="item.type === 'expiresAt'">
                <span v-gl-tooltip="expiryTimestamp" data-testid="token-expiry">
                  {{ expiryDate }}
                </span>
              </template>

              <template v-else-if="item.type === 'lastUsedAt'">
                <span v-gl-tooltip="lastUsedTimestamp" data-testid="token-last-used">
                  {{ lastUsedDate }}
                </span>
              </template>

              <template v-else-if="item.type === 'ipUsage'">
                <template v-if="token.lastUsedIps.length">
                  <div v-for="(ip, index) in token.lastUsedIps" :key="index" class="gl-mb-2">
                    {{ ip }}
                  </div>
                </template>
                <template v-else>
                  <span class="gl-text-subtle">{{ $options.i18n.noIpUsage }}</span>
                </template>
              </template>
            </template>
          </gl-attribute-list>

          <crud-component class="gl-mt-5">
            <template #title>
              <gl-icon name="token-permissions" />
              <span>{{ $options.i18n.scopes }}</span>
            </template>

            <personal-access-token-granular-scopes v-if="isTokenGranular" :scopes="token.scopes" />
            <personal-access-token-legacy-scopes v-else :scopes="token.scopes" />
          </crud-component>
        </section>
      </div>
    </div>
  </mounting-portal>
</template>
