<script>
import { GlIcon, GlLink, GlPagination, GlTable, GlTooltipDirective } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { __ } from '~/locale';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import UserDate from '~/vue_shared/components/user_date.vue';
import { INACTIVE_TOKENS_TABLE_FIELDS, INITIAL_PAGE, PAGE_SIZE } from './constants';

export default {
  PAGE_SIZE,
  name: 'InactiveAccessTokenTableApp',
  components: {
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
    revoked: __('Revoked'),
  },
  INACTIVE_TOKENS_TABLE_FIELDS,
  inject: [
    'accessTokenType',
    'accessTokenTypePlural',
    'initialInactiveAccessTokens',
    'noInactiveTokensMessage',
  ],
  data() {
    return {
      inactiveAccessTokens: convertObjectPropsToCamelCase(this.initialInactiveAccessTokens, {
        deep: true,
      }),
      currentPage: INITIAL_PAGE,
    };
  },
  computed: {
    showPagination() {
      return this.inactiveAccessTokens.length > PAGE_SIZE;
    },
  },
  methods: {
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
  <div>
    <gl-table
      data-testid="inactive-access-tokens"
      :empty-text="noInactiveTokensMessage"
      :fields="$options.INACTIVE_TOKENS_TABLE_FIELDS"
      :items="inactiveAccessTokens"
      :per-page="$options.PAGE_SIZE"
      :current-page="currentPage"
      :sort-compare="sortingChanged"
      show-empty
      stacked="sm"
      class="gl-overflow-x-auto"
    >
      <template #cell(createdAt)="{ item: { createdAt } }">
        <user-date :date="createdAt" />
      </template>

      <template #head(lastUsedAt)="{ label }">
        <span>{{ label }}</span>
        <gl-link :href="$options.lastUsedHelpLink"
          ><gl-icon name="question-o" class="gl-ml-2" /><span class="gl-sr-only">{{
            s__('AccessTokens|The last time a token was used')
          }}</span></gl-link
        >
      </template>

      <template #cell(lastUsedAt)="{ item: { lastUsedAt } }">
        <time-ago-tooltip v-if="lastUsedAt" :time="lastUsedAt" />
        <template v-else> {{ $options.i18n.emptyField }}</template>
      </template>

      <template #cell(expiresAt)="{ item: { expiresAt, revoked } }">
        <span v-if="revoked" v-gl-tooltip :title="$options.i18n.tokenValidity">{{
          $options.i18n.revoked
        }}</span>
        <template v-else>
          <span>{{ $options.i18n.expired }}</span>
          <time-ago-tooltip :time="expiresAt" />
        </template>
      </template>
    </gl-table>
    <gl-pagination
      v-if="showPagination"
      v-model="currentPage"
      :per-page="$options.PAGE_SIZE"
      :total-items="inactiveAccessTokens.length"
      :prev-text="__('Prev')"
      :next-text="__('Next')"
      :label-next-page="__('Go to next page')"
      :label-prev-page="__('Go to previous page')"
      align="center"
      class="gl-mt-5"
    />
  </div>
</template>
