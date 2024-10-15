<script>
import { GlButton, GlIcon, GlLink, GlPagination, GlTable, GlTooltipDirective } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import axios from '~/lib/utils/axios_utils';
import {
  convertObjectPropsToCamelCase,
  normalizeHeaders,
  parseIntPagination,
} from '~/lib/utils/common_utils';
import { __, sprintf } from '~/locale';
import DomElementListener from '~/vue_shared/components/dom_element_listener.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import UserDate from '~/vue_shared/components/user_date.vue';
import { EVENT_SUCCESS, FIELDS, FORM_SELECTOR, INITIAL_PAGE, PAGE_SIZE } from './constants';

/**
 * This component supports two different types of pagination:
 * 1. Frontend only pagination: all the data is passed to the frontend. The UI slices and displays the tokens.
 * 2. Backend pagination: backend sends only the data corresponding to the `page` parameter.
 */

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
    modalMessage: __(
      'Are you sure you want to revoke the %{accessTokenType} "%{tokenName}"? This action cannot be undone.',
    ),
    revokeButton: __('Revoke'),
    tokenValidity: __('Token valid until revoked'),
  },
  inject: [
    'accessTokenType',
    'accessTokenTypePlural',
    'backendPagination',
    'initialActiveAccessTokens',
    'noActiveTokensMessage',
    'showRole',
  ],
  data() {
    const activeAccessTokens = this.convert(this.initialActiveAccessTokens);

    return {
      activeAccessTokens,
      busy: false,
      currentPage: INITIAL_PAGE, // This is the page use in the GlTable. It stays 1 if the backend pagination is on.
      page: INITIAL_PAGE, // This is the page use in the GlPagination component
      perPage: PAGE_SIZE,
      totalItems: activeAccessTokens.length,
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

      const fields = FIELDS.filter(({ key }) => !ignoredFields.includes(key));

      // Remove the sortability of the columns if backend pagination is on.
      if (this.backendPagination) {
        return fields.map((field) => ({
          ...field,
          sortable: false,
        }));
      }

      return fields;
    },
    showPagination() {
      return this.totalItems > this.perPage;
    },
  },
  created() {
    if (this.backendPagination) {
      this.fetchData();
    }
  },
  methods: {
    convert(accessTokens) {
      return convertObjectPropsToCamelCase(accessTokens, { deep: true });
    },
    async fetchData(newPage) {
      const url = new URL(document.location.href);
      url.pathname = `${url.pathname}.json`;

      if (newPage) {
        url.searchParams.delete('page');
        url.searchParams.append('page', newPage);
      }

      this.busy = true;
      const { data, headers } = await axios.get(url.toString());

      const { page, perPage, total } = parseIntPagination(normalizeHeaders(headers));
      this.page = page;
      this.perPage = perPage;
      this.totalItems = total;
      this.busy = false;

      if (newPage) {
        this.activeAccessTokens = this.convert(data);
        this.replaceHistory(newPage);
      }
    },
    replaceHistory(page) {
      window.history.replaceState(null, '', `?page=${page}`);
    },
    onSuccess(event) {
      const [{ active_access_tokens: activeAccessTokens, total: totalItems }] = event.detail;
      this.activeAccessTokens = this.convert(activeAccessTokens);
      this.totalItems = totalItems;
      this.currentPage = INITIAL_PAGE;
      this.page = INITIAL_PAGE;

      if (this.backendPagination) {
        this.replaceHistory(INITIAL_PAGE);
      }
    },
    modalMessage(tokenName) {
      return sprintf(this.$options.i18n.modalMessage, {
        accessTokenType: this.accessTokenType,
        tokenName,
      });
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
    async pageChanged(newPage) {
      if (this.backendPagination) {
        await this.fetchData(newPage);
      } else {
        this.currentPage = newPage;
        this.page = newPage;
      }
      window.scrollTo({ top: 0 });
    },
  },
};
</script>

<template>
  <dom-element-listener :selector="$options.FORM_SELECTOR" @[$options.EVENT_SUCCESS]="onSuccess">
    <div>
      <div>
        <gl-table
          data-testid="active-tokens"
          :empty-text="noActiveTokensMessage"
          :fields="filteredFields"
          :items="activeAccessTokens"
          :per-page="perPage"
          :current-page="currentPage"
          :sort-compare="sortingChanged"
          show-empty
          stacked="sm"
          :busy="busy"
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

          <template #cell(expiresAt)="{ item: { expiresAt, expired, expiresSoon } }">
            <template v-if="expiresAt">
              <span v-if="expired" class="gl-text-danger">{{ $options.i18n.expired }}</span>
              <time-ago-tooltip v-else :class="{ 'text-warning': expiresSoon }" :time="expiresAt" />
            </template>
            <span v-else v-gl-tooltip :title="$options.i18n.tokenValidity">{{
              $options.i18n.emptyField
            }}</span>
          </template>

          <template #cell(action)="{ item: { name, revokePath } }">
            <gl-button
              v-if="revokePath"
              category="tertiary"
              :title="$options.i18n.revokeButton"
              :aria-label="$options.i18n.revokeButton"
              :data-confirm="modalMessage(name)"
              data-confirm-btn-variant="danger"
              data-testid="revoke-button"
              data-method="put"
              :href="revokePath"
              icon="remove"
              class="has-tooltip"
            />
          </template>
        </gl-table>
      </div>
      <gl-pagination
        v-if="showPagination"
        :value="page"
        :per-page="perPage"
        :total-items="totalItems"
        :disabled="busy"
        align="center"
        class="gl-mt-5"
        @input="pageChanged"
      />
    </div>
  </dom-element-listener>
</template>
