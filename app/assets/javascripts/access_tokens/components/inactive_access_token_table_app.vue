<script>
import { GlLink, GlPagination, GlTable, GlTooltipDirective } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import axios from '~/lib/utils/axios_utils';
import {
  convertObjectPropsToCamelCase,
  normalizeHeaders,
  parseIntPagination,
} from '~/lib/utils/common_utils';
import { s__, __ } from '~/locale';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';
import UserDate from '~/vue_shared/components/user_date.vue';
import { INACTIVE_TOKENS_TABLE_FIELDS } from './constants';

export default {
  name: 'InactiveAccessTokenTableApp',
  components: {
    GlLink,
    GlPagination,
    GlTable,
    TimeAgoTooltip,
    UserDate,
    HelpIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  lastUsedHelpLink: helpPagePath('/user/profile/personal_access_tokens.md', {
    anchor: 'view-the-time-at-and-ips-where-a-token-was-last-used',
  }),
  i18n: {
    emptyField: __('Never'),
    expired: __('Expired'),
    revoked: __('Revoked'),
    lastTimeUsed: s__('AccessTokens|The last time a token was used'),
    errorFetching: s__('AccessTokens|An error occurred while fetching the tokens.'),
  },
  inject: ['noInactiveTokensMessage', 'paginationUrl'],
  data() {
    return {
      inactiveAccessTokens: [],
      busy: false,
      emptyText: '',
      page: 1,
      perPage: 0,
      total: 0,
    };
  },
  computed: {
    filteredFields() {
      // Remove the sortability of the columns
      return INACTIVE_TOKENS_TABLE_FIELDS.map((field) => ({
        ...field,
        sortable: false,
      }));
    },
    showPagination() {
      return this.total > this.perPage;
    },
  },
  created() {
    this.fetchData();
  },
  methods: {
    async fetchData(newPage = '1') {
      const url = new URL(this.paginationUrl);
      url.searchParams.append('page', newPage);

      this.busy = true;
      try {
        const { data, headers } = await axios.get(url.toString());

        const { page, perPage, total } = parseIntPagination(normalizeHeaders(headers));
        this.page = page;
        this.perPage = perPage;
        this.total = total;
        this.inactiveAccessTokens = convertObjectPropsToCamelCase(data, { deep: true });
        this.emptyText = this.noInactiveTokensMessage;
      } catch {
        this.inactiveAccessTokens = [];
        this.emptyText = this.$options.i18n.errorFetching;
      } finally {
        this.busy = false;
      }
    },
    async pageChanged(newPage) {
      await this.fetchData(newPage.toString());
    },
  },
};
</script>

<template>
  <div>
    <gl-table
      data-testid="inactive-access-tokens"
      :empty-text="emptyText"
      :fields="filteredFields"
      :items="inactiveAccessTokens"
      show-empty
      stacked="sm"
      class="gl-overflow-x-auto"
      :busy="busy"
    >
      <template #cell(createdAt)="{ item: { createdAt } }">
        <user-date :date="createdAt" />
      </template>

      <template #head(lastUsedAt)="{ label }">
        <span>{{ label }}</span>
        <gl-link :href="$options.lastUsedHelpLink"
          ><help-icon class="gl-ml-2" /><span class="gl-sr-only">{{
            $options.i18n.lastTimeUsed
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
      :value="page"
      :per-page="perPage"
      :total-items="total"
      :disabled="busy"
      align="center"
      class="gl-mt-5"
      @input="pageChanged"
    />
  </div>
</template>
