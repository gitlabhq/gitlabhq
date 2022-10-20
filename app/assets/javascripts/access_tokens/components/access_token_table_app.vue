<script>
import { GlButton, GlIcon, GlLink, GlPagination, GlTable, GlTooltipDirective } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { __, sprintf } from '~/locale';
import DomElementListener from '~/vue_shared/components/dom_element_listener.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import UserDate from '~/vue_shared/components/user_date.vue';
import { EVENT_SUCCESS, FIELDS, FORM_SELECTOR, INITIAL_PAGE, PAGE_SIZE } from './constants';

export default {
  EVENT_SUCCESS,
  FORM_SELECTOR,
  PAGE_SIZE,
  name: 'AccessTokenTableApp',
  components: {
    DomElementListener,
    GlButton,
    GlIcon,
    GlLink,
    GlPagination,
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
  inject: [
    'accessTokenType',
    'accessTokenTypePlural',
    'initialActiveAccessTokens',
    'noActiveTokensMessage',
    'showRole',
    'information',
  ],
  data() {
    return {
      activeAccessTokens: convertObjectPropsToCamelCase(this.initialActiveAccessTokens, {
        deep: true,
      }),
      currentPage: INITIAL_PAGE,
    };
  },
  computed: {
    filteredFields() {
      const ignoredFields = [];

      // Show 'action' column only when there are no active tokens or when some of them have a revokePath
      const showAction =
        this.activeAccessTokens.length === 0 ||
        this.activeAccessTokens.some((token) => token.revokePath);

      if (!showAction) {
        ignoredFields.push('action');
      }

      if (!this.showRole) {
        ignoredFields.push('role');
      }

      return FIELDS.filter(({ key }) => !ignoredFields.includes(key));
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
    showPagination() {
      return this.activeAccessTokens.length > PAGE_SIZE;
    },
  },
  methods: {
    onSuccess(event) {
      const [{ active_access_tokens: activeAccessTokens }] = event.detail;
      this.activeAccessTokens = convertObjectPropsToCamelCase(activeAccessTokens, { deep: true });
      this.currentPage = INITIAL_PAGE;
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
  <dom-element-listener :selector="$options.FORM_SELECTOR" @[$options.EVENT_SUCCESS]="onSuccess">
    <div>
      <hr />
      <h5>{{ header }}</h5>

      <p v-if="information" data-testid="information-section">
        {{ information }}
      </p>

      <gl-table
        data-testid="active-tokens"
        :empty-text="noActiveTokensMessage"
        :fields="filteredFields"
        :items="activeAccessTokens"
        :per-page="$options.PAGE_SIZE"
        :current-page="currentPage"
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

        <template #cell(action)="{ item: { revokePath } }">
          <gl-button
            v-if="revokePath"
            category="tertiary"
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
      <gl-pagination
        v-if="showPagination"
        v-model="currentPage"
        :per-page="$options.PAGE_SIZE"
        :total-items="activeAccessTokens.length"
        :prev-text="__('Prev')"
        :next-text="__('Next')"
        :label-next-page="__('Go to next page')"
        :label-prev-page="__('Go to previous page')"
        align="center"
      />
    </div>
  </dom-element-listener>
</template>
