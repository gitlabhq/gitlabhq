<script>
import { GlButton, GlIcon, GlLink, GlTable, GlTooltipDirective } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { __, s__, sprintf } from '~/locale';
import DomElementListener from '~/vue_shared/components/dom_element_listener.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import UserDate from '~/vue_shared/components/user_date.vue';

const FORM_SELECTOR = '#js-new-access-token-form';
const SUCCESS_EVENT = 'ajax:success';

export default {
  FORM_SELECTOR,
  SUCCESS_EVENT,
  name: 'AccessTokenTableApp',
  components: {
    DomElementListener,
    GlButton,
    GlIcon,
    GlLink,
    GlTable,
    TimeAgoTooltip,
    UserDate,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  lastUsedHelpLink: helpPagePath('/user/profile/personal_access_tokens.md', {
    anchor: 'view-the-last-time-a-token-was-used',
  }),
  i18n: {
    emptyField: __('Never'),
    expired: __('Expired'),
    header: __('Active %{accessTokenTypePlural} (%{totalAccessTokens})'),
    modalMessage: __(
      'Are you sure you want to revoke this %{accessTokenType}? This action cannot be undone.',
    ),
    revokeButton: __('Revoke'),
    tokenValidity: __('Token valid until revoked'),
  },
  fields: [
    {
      key: 'name',
      label: __('Token name'),
      sortable: true,
      tdClass: `gl-text-black-normal`,
      thClass: `gl-text-black-normal`,
    },
    {
      formatter(scopes) {
        return scopes?.length ? scopes.join(', ') : __('no scopes selected');
      },
      key: 'scopes',
      label: __('Scopes'),
      sortable: true,
      tdClass: `gl-text-black-normal`,
      thClass: `gl-text-black-normal`,
    },
    {
      key: 'createdAt',
      label: s__('AccessTokens|Created'),
      sortable: true,
      tdClass: `gl-text-black-normal`,
      thClass: `gl-text-black-normal`,
    },
    {
      key: 'lastUsedAt',
      label: __('Last Used'),
      sortable: true,
      tdClass: `gl-text-black-normal`,
      thClass: `gl-text-black-normal`,
    },
    {
      key: 'expiresAt',
      label: __('Expires'),
      sortable: true,
      tdClass: `gl-text-black-normal`,
      thClass: `gl-text-black-normal`,
    },
    {
      key: 'role',
      label: __('Role'),
      tdClass: `gl-text-black-normal`,
      thClass: `gl-text-black-normal`,
      sortable: true,
    },
    {
      key: 'action',
      label: __('Action'),
      thClass: `gl-text-black-normal`,
    },
  ],
  inject: [
    'accessTokenType',
    'accessTokenTypePlural',
    'initialActiveAccessTokens',
    'noActiveTokensMessage',
    'showRole',
  ],
  data() {
    return {
      activeAccessTokens: this.initialActiveAccessTokens,
    };
  },
  computed: {
    filteredFields() {
      return this.showRole
        ? this.$options.fields
        : this.$options.fields.filter((field) => field.key !== 'role');
    },
    header() {
      return sprintf(this.$options.i18n.header, {
        accessTokenTypePlural: this.accessTokenTypePlural,
        totalAccessTokens: this.activeAccessTokens.length,
      });
    },
    modalMessage() {
      return sprintf(this.$options.i18n.modalMessage, {
        accessTokenType: this.accessTokenType,
      });
    },
  },
  methods: {
    onSuccess(event) {
      const [{ active_access_tokens: activeAccessTokens }] = event.detail;
      this.activeAccessTokens = convertObjectPropsToCamelCase(activeAccessTokens, { deep: true });
    },
    sortingChanged(aRow, bRow, key) {
      if (['createdAt', 'lastUsedAt', 'expiresAt'].includes(key)) {
        // Transform `null` value to the latest possible date
        // https://stackoverflow.com/a/11526569/18428169
        const maxEpoch = 8640000000000000;
        const a = new Date(aRow[key] ?? maxEpoch).getTime();
        const b = new Date(bRow[key] ?? maxEpoch).getTime();
        return a - b;
      }

      // For other columns the default sorting works OK
      return false;
    },
  },
};
</script>

<template>
  <dom-element-listener :selector="$options.FORM_SELECTOR" @[$options.SUCCESS_EVENT]="onSuccess">
    <div>
      <hr />
      <h5>{{ header }}</h5>

      <gl-table
        data-testid="active-tokens"
        :empty-text="noActiveTokensMessage"
        :fields="filteredFields"
        :items="activeAccessTokens"
        :sort-compare="sortingChanged"
        show-empty
      >
        <template #cell(createdAt)="{ item: { createdAt } }">
          <user-date :date="createdAt" />
        </template>

        <template #head(lastUsedAt)="{ label }">
          <span>{{ label }}</span>
          <gl-link :href="$options.lastUsedHelpLink"
            ><gl-icon name="question-o" /><span class="gl-sr-only">{{
              s__('AccessTokens|The last time a token was used')
            }}</span></gl-link
          >
        </template>

        <template #cell(lastUsedAt)="{ item: { lastUsedAt } }">
          <time-ago-tooltip v-if="lastUsedAt" :time="lastUsedAt" />
          <template v-else> {{ $options.i18n.emptyField }}</template>
        </template>

        <template #cell(expiresAt)="{ item: { expiresAt, expired, expiresSoon } }">
          <template v-if="expiresAt">
            <span v-if="expired" class="text-danger">{{ $options.i18n.expired }}</span>
            <time-ago-tooltip v-else :class="{ 'text-warning': expiresSoon }" :time="expiresAt" />
          </template>
          <span v-else v-gl-tooltip :title="$options.i18n.tokenValidity">{{
            $options.i18n.emptyField
          }}</span>
        </template>

        <template #cell(action)="{ item: { revokePath, expiresAt } }">
          <gl-button
            variant="danger"
            :category="expiresAt ? 'primary' : 'secondary'"
            :aria-label="$options.i18n.revokeButton"
            :data-confirm="modalMessage"
            data-confirm-btn-variant="danger"
            data-qa-selector="revoke_button"
            data-method="put"
            :href="revokePath"
            icon="remove"
          />
        </template>
      </gl-table>
    </div>
  </dom-element-listener>
</template>
