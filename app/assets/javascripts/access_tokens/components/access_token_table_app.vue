<script>
import { GlButton, GlLink, GlModal, GlPagination, GlTable, GlTooltipDirective } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import axios from '~/lib/utils/axios_utils';
import {
  convertObjectPropsToCamelCase,
  normalizeHeaders,
  parseIntPagination,
} from '~/lib/utils/common_utils';
import { __, s__, sprintf } from '~/locale';
import DomElementListener from '~/vue_shared/components/dom_element_listener.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';
import UserDate from '~/vue_shared/components/user_date.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { createAlert, VARIANT_DANGER } from '~/alert';
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
    GlLink,
    GlModal,
    GlPagination,
    GlTable,
    TimeAgoTooltip,
    UserDate,
    HelpIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagsMixin()],
  lastUsedHelpLink: helpPagePath('/user/profile/personal_access_tokens.md', {
    anchor: 'view-the-time-at-and-ips-where-a-token-was-last-used',
  }),
  i18n: {
    button: {
      revoke: s__('AccessTokens|Revoke'),
      rotate: s__('AccessTokens|Rotate'),
    },
    emptyDateField: __('Never'),
    expired: __('Expired'),
    lastTimeUsed: s__('AccessTokens|The last time a token was used'),
    tokenValidity: __('Token valid until revoked'),
    modal: {
      message: {
        revoke: s__(
          'AccessTokens|Are you sure you want to revoke the %{accessTokenType} "%{tokenName}"? This action cannot be undone. Any tools that rely on this access token will stop working.',
        ),
        rotate: s__(
          'AccessTokens|Are you sure you want to rotate the %{accessTokenType} "%{tokenName}"? This action cannot be undone. Any tools that rely on this access token will stop working.',
        ),
      },
      actionCancel: {
        text: __('Cancel'),
      },
    },
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
      accessTokenName: '',
      accessTokenPath: '',
      activeAccessTokens,
      alert: null,
      busy: false,
      currentPage: INITIAL_PAGE, // This is the page use in the GlTable. It stays 1 if the backend pagination is on.
      modalVisible: false,
      page: INITIAL_PAGE, // This is the page use in the GlPagination component
      perPage: PAGE_SIZE,
      totalItems: activeAccessTokens.length,
    };
  },
  computed: {
    actionPrimary() {
      return {
        text: this.$options.i18n.button.rotate,
        attributes: {
          variant: 'danger',
        },
      };
    },
    filteredFields() {
      const ignoredFields = [];

      // Show 'action' column only when there are no active tokens or when some of them have a revokePath or rotatePath
      const showAction =
        this.activeAccessTokens.length === 0 ||
        this.activeAccessTokens.some((token) => token.revokePath || token.rotatePath);

      if (!showAction) {
        ignoredFields.push('action');
      }

      if (!this.showRole) {
        ignoredFields.push('role');
      }

      if (!this.glFeatures.patIp) {
        ignoredFields.push('lastUsedIps');
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
    toggleModal(name, path) {
      this.modalVisible = !this.modalVisible;
      this.accessTokenName = name;
      this.accessTokenPath = path;
    },
    // Received when new token is created in new_access_token_app.vue
    onSuccess(event) {
      const [{ active_access_tokens: activeAccessTokens, total: totalItems }] = event.detail;
      this.updateAccessTokens(activeAccessTokens, totalItems);
    },
    async handleAccessTokenRotation() {
      try {
        this.alert?.dismiss();

        const { data } = await axios.put(this.accessTokenPath);
        const { active_access_tokens: activeAccessTokens, total: totalItems } = data;

        this.updateAccessTokens(activeAccessTokens, totalItems);

        // Trigger an event on new_access_token_app.vue to display the new token (on rotate)
        const newAccessTokenForm = document.querySelector(FORM_SELECTOR);
        if (newAccessTokenForm) {
          const event = new CustomEvent(EVENT_SUCCESS, {
            detail: [data],
          });
          newAccessTokenForm.dispatchEvent(event);
        }
      } catch (error) {
        if (error.response?.data?.message) {
          this.alert = createAlert({
            message: error.response.data.message,
            variant: VARIANT_DANGER,
          });
        }
      } finally {
        this.modalVisible = false;
      }
    },
    updateAccessTokens(activeAccessTokens, totalItems) {
      this.activeAccessTokens = this.convert(activeAccessTokens);
      this.totalItems = totalItems;
      this.currentPage = INITIAL_PAGE;
      this.page = INITIAL_PAGE;

      if (this.backendPagination) {
        this.replaceHistory(INITIAL_PAGE);
      }
    },
    modalMessage(tokenName, action) {
      return sprintf(this.$options.i18n.modal.message[action], {
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
          <template #cell(name)="{ item: { name } }">
            <span class="gl-font-normal">{{ name }}</span>
          </template>
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
            <template v-else> {{ $options.i18n.emptyDateField }}</template>
          </template>

          <template #head(lastUsedIps)="{ label }">
            <span>{{ label }}</span>
            <gl-link :href="$options.lastUsedHelpLink"
              ><help-icon class="gl-ml-2" /><span class="gl-sr-only">{{
                s__(
                  'AccessTokens|The last five distinct IP addresses from where the token was used',
                )
              }}</span></gl-link
            >
          </template>

          <template #cell(expiresAt)="{ item: { expiresAt, expired, expiresSoon } }">
            <template v-if="expiresAt">
              <span v-if="expired" class="gl-text-danger">{{ $options.i18n.expired }}</span>
              <time-ago-tooltip v-else :class="{ 'text-warning': expiresSoon }" :time="expiresAt" />
            </template>
            <span v-else v-gl-tooltip :title="$options.i18n.tokenValidity">{{
              $options.i18n.emptyDateField
            }}</span>
          </template>

          <template #cell(action)="{ item: { name, revokePath, rotatePath } }">
            <gl-button
              v-if="revokePath"
              category="tertiary"
              :title="$options.i18n.button.revoke"
              :aria-label="$options.i18n.button.revoke"
              :data-confirm="modalMessage(name, 'revoke')"
              data-confirm-btn-variant="danger"
              data-testid="revoke-button"
              data-method="put"
              :href="revokePath"
              icon="remove"
              class="has-tooltip"
            />
            <gl-button
              v-if="rotatePath"
              category="tertiary"
              :title="$options.i18n.button.rotate"
              :aria-label="$options.i18n.button.rotate"
              data-testid="rotate-button"
              icon="retry"
              class="has-tooltip"
              @click="toggleModal(name, rotatePath)"
            />
          </template>
        </gl-table>
        <gl-modal
          v-model="modalVisible"
          :action-cancel="$options.i18n.modal.actionCancel"
          :action-primary="actionPrimary"
          modal-id="token-action-modal"
          size="sm"
          hide-header
          @primary="handleAccessTokenRotation"
        >
          {{ modalMessage(accessTokenName, 'rotate') }}
        </gl-modal>
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
