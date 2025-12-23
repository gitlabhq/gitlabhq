<script>
import {
  GlTable,
  GlLoadingIcon,
  GlIcon,
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlTooltipDirective,
  GlSprintf,
  GlButton,
} from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { timeFormattedAsDate, timeFormattedAsDateFull } from '../utils';
import { TABLE_FIELDS } from '../constants';
import PersonalAccessTokenStatusBadge from './personal_access_token_status_badge.vue';

export default {
  name: 'PersonalAccessTokensTable',
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlLoadingIcon,
    GlTable,
    GlIcon,
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlSprintf,
    GlButton,
    PersonalAccessTokenStatusBadge,
  },
  props: {
    tokens: {
      type: Array,
      required: true,
    },
    loading: {
      type: Boolean,
      required: true,
    },
  },
  emits: ['select', 'rotate', 'revoke'],
  methods: {
    selectTargetToken(token) {
      this.$emit('select', token);
    },
    rotateTargetToken(token) {
      this.$emit('rotate', token);
    },
    revokeTargetToken(token) {
      this.$emit('revoke', token);
    },
    expiryDate(token) {
      return timeFormattedAsDate(token.expiresAt);
    },
    expiryTimestamp(token) {
      return timeFormattedAsDateFull(token.expiresAt);
    },
    lastUsedDate(token) {
      return timeFormattedAsDate(token.lastUsedAt);
    },
    lastUsedTimestamp(token) {
      return timeFormattedAsDateFull(token.lastUsedAt);
    },
  },
  i18n: {
    noAccessTokens: s__('AccessTokens|No access tokens'),
    noDescription: s__('AccessTokens|No description provided.'),
    expires: s__('AccessTokens|Expires: %{date}'),
    lastUsed: s__('AccessTokens|Last used: %{date}'),
    actions: __('Actions'),
    viewDetails: s__('AccessTokens|View details'),
    rotate: s__('AccessTokens|Rotate'),
    revoke: s__('AccessTokens|Revoke'),
  },
  TABLE_FIELDS,
};
</script>

<template>
  <gl-table
    :items="tokens"
    :fields="$options.TABLE_FIELDS"
    :busy="loading"
    stacked="md"
    show-empty
    :empty-text="$options.i18n.noAccessTokens"
  >
    <template #table-busy>
      <gl-loading-icon size="md" />
    </template>

    <template #cell(name)="{ item, value }">
      <gl-button variant="link" @click="selectTargetToken(item)">
        {{ value }}
      </gl-button>
    </template>

    <template #cell(description)="{ value }">
      <div>
        <span v-if="value">{{ value }}</span>
        <span v-else class="gl-text-subtle">
          {{ $options.i18n.noDescription }}
        </span>
      </div>
    </template>

    <template #cell(status)="{ item }">
      <div
        class="gl-flex gl-flex-wrap gl-items-center gl-justify-end gl-gap-3 @md/panel:gl-justify-start"
      >
        <div v-gl-tooltip="expiryTimestamp(item)" data-testid="token-expiry">
          <gl-icon name="expire" class="gl-mr-2" />
          <gl-sprintf :message="$options.i18n.expires">
            <template #date>{{ expiryDate(item) }}</template>
          </gl-sprintf>
        </div>
        <personal-access-token-status-badge :token="item" />
      </div>

      <div class="gl-mt-3 gl-flex gl-justify-end lg:gl-justify-start">
        <div v-gl-tooltip.d0="lastUsedTimestamp(item)" data-testid="token-last-used">
          <gl-icon name="hourglass" class="gl-mr-2" />
          <gl-sprintf :message="$options.i18n.lastUsed">
            <template #date>{{ lastUsedDate(item) }}</template>
          </gl-sprintf>
        </div>
      </div>
    </template>

    <template #cell(actions)="{ item }">
      <gl-disclosure-dropdown
        category="tertiary"
        icon="ellipsis_v"
        no-caret
        placement="bottom-end"
        :toggle-text="$options.i18n.actions"
        text-sr-only
      >
        <gl-disclosure-dropdown-item @action="selectTargetToken(item)">
          <template #list-item>{{ $options.i18n.viewDetails }}</template>
        </gl-disclosure-dropdown-item>
        <gl-disclosure-dropdown-item v-if="item.active" @action="rotateTargetToken(item)">
          <template #list-item>{{ $options.i18n.rotate }}</template>
        </gl-disclosure-dropdown-item>
        <gl-disclosure-dropdown-item
          v-if="item.active"
          variant="danger"
          @action="revokeTargetToken(item)"
        >
          <template #list-item>{{ $options.i18n.revoke }}</template>
        </gl-disclosure-dropdown-item>
      </gl-disclosure-dropdown>
    </template>
  </gl-table>
</template>
