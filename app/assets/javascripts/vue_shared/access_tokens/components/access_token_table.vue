<script>
import {
  GlBadge,
  GlDisclosureDropdown,
  GlIcon,
  GlLink,
  GlModal,
  GlSprintf,
  GlTable,
  GlTooltipDirective,
} from '@gitlab/ui';
import { mapActions } from 'pinia';
import { helpPagePath } from '~/helpers/help_page_helper';
import { __, s__, sprintf } from '~/locale';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import UserDate from '~/vue_shared/components/user_date.vue';

import { useAccessTokens } from '../stores/access_tokens';
import { fifteenDaysFromNow, resetCreatedTime, utcExpiredDate } from '../utils';

const REVOKE = 'revoke';
const ROTATE = 'rotate';

export default {
  components: {
    GlBadge,
    GlDisclosureDropdown,
    GlIcon,
    GlLink,
    GlModal,
    GlSprintf,
    GlTable,
    HelpIcon,
    TimeAgoTooltip,
    UserDate,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    busy: {
      type: Boolean,
      required: true,
    },
    tokens: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      action: REVOKE,
      selectedToken: null,
      showModal: false,
    };
  },
  computed: {
    actionPrimary() {
      return {
        text: this.$options.i18n.modal.button[this.action],
        attributes: {
          variant: 'danger',
        },
      };
    },
    modalTitle() {
      return sprintf(
        this.$options.i18n.modal.title[this.action],
        {
          tokenName: this.selectedToken?.name,
        },
        false,
      );
    },
  },
  methods: {
    ...mapActions(useAccessTokens, ['revokeToken', 'rotateToken']),
    actionToken() {
      if (this.action === REVOKE) {
        this.revokeToken(this.selectedToken.id);
      } else if (this.action === ROTATE) {
        this.rotateToken(this.selectedToken.id, this.selectedToken.expiresAt);
      }
    },
    isExpiring(expiresAt) {
      if (expiresAt) {
        return expiresAt < fifteenDaysFromNow();
      }

      return false;
    },
    options(item) {
      return [
        {
          action: () => {
            this.toggleModal({ action: ROTATE, item });
          },
          text: s__('AccessTokens|Rotate'),
        },
        {
          action: () => {
            this.toggleModal({ action: REVOKE, item });
          },
          text: s__('AccessTokens|Revoke'),
          variant: 'danger',
        },
      ];
    },
    toggleModal({ action, item }) {
      this.action = action;
      this.showModal = true;
      this.selectedToken = item;
    },
  },
  usage: helpPagePath('/user/profile/personal_access_tokens.md', {
    anchor: 'view-token-usage-information',
  }),
  fields: [
    {
      key: 'name',
      label: s__('AccessTokens|Name'),
    },
    {
      key: 'status',
      label: s__('AccessTokens|Status'),
    },
    {
      formatter: (property) => (property?.length ? property.join(', ') : '-'),
      key: 'scopes',
      label: s__('AccessTokens|Scopes'),
      tdAttr: { 'data-testid': 'cell-scopes' },
    },
    {
      key: 'usage',
      label: s__('AccessTokens|Usage'),
      thAttr: { 'data-testid': 'header-usage' },
    },
    {
      key: 'lifetime',
      label: s__('AccessTokens|Lifetime'),
    },
    {
      key: 'options',
      label: '',
      tdClass: 'gl-text-end',
    },
  ],
  i18n: {
    modal: {
      actionCancel: {
        text: __('Cancel'),
      },
      button: {
        revoke: s__('AccessTokens|Revoke'),
        rotate: s__('AccessTokens|Rotate'),
      },
      message: {
        revoke: s__(
          'AccessTokens|Are you sure you want to revoke the token %{tokenName}? This action cannot be undone. Any tools that rely on this access token will stop working.',
        ),

        rotate: s__(
          'AccessTokens|Are you sure you want to rotate the token %{tokenName}? This action cannot be undone. Any tools that rely on this access token will stop working.',
        ),
      },
      title: {
        revoke: s__("AccessTokens|Revoke the token '%{tokenName}'?"),
        rotate: s__("AccessTokens|Rotate the token '%{tokenName}'?"),
      },
    },
  },
  resetCreatedTime,
  utcExpiredDate,
};
</script>

<template>
  <div>
    <gl-table
      data-testid="access-token-table"
      :items="tokens"
      :fields="$options.fields"
      :empty-text="s__('AccessTokens|No access tokens')"
      show-empty
      stacked="md"
      :busy="busy"
    >
      <template #head(usage)="{ label }">
        <span>{{ label }}</span>
        <gl-link :href="$options.usage"
          ><help-icon class="gl-ml-2" /><span class="gl-sr-only">{{
            s__('AccessTokens|View token usage information')
          }}</span></gl-link
        >
      </template>

      <template #cell(name)="{ item: { name, description } }">
        <div data-testid="field-name" class="gl-font-bold">{{ name }}</div>
        <div v-if="description" data-testid="field-description" class="gl-mt-3">
          {{ description }}
        </div>
      </template>

      <template #cell(status)="{ item: { active, revoked, expiresAt } }">
        <template v-if="active">
          <template v-if="isExpiring(expiresAt)">
            <gl-badge
              v-gl-tooltip
              :title="s__('AccessTokens|Token expires in less than two weeks.')"
              variant="warning"
              icon="expire"
              icon-optically-aligned
              >{{ s__('AccessTokens|Expiring') }}</gl-badge
            >
          </template>
          <template v-else>
            <gl-badge variant="success" icon="check-circle" icon-optically-aligned>{{
              s__('AccessTokens|Active')
            }}</gl-badge>
          </template>
        </template>
        <template v-else-if="revoked">
          <gl-badge variant="neutral" icon="remove" icon-optically-aligned>{{
            s__('AccessTokens|Revoked')
          }}</gl-badge>
        </template>
        <template v-else>
          <gl-badge variant="neutral" icon="time-out" icon-optically-aligned>{{
            s__('AccessTokens|Expired')
          }}</gl-badge>
        </template>
      </template>

      <template #cell(usage)="{ item: { lastUsedAt, lastUsedIps } }">
        <div data-testid="field-last-used">
          <span>{{ s__('AccessTokens|Last used:') }}</span>
          <time-ago-tooltip v-if="lastUsedAt" :time="lastUsedAt" />
          <template v-else>{{ __('Never') }}</template>
        </div>

        <div
          v-if="lastUsedIps && lastUsedIps.length"
          class="gl-mt-3"
          data-testid="field-last-used-ips"
        >
          <gl-sprintf
            :message="
              n__('AccessTokens|IP: %{ips}', 'AccessTokens|IPs: %{ips}', lastUsedIps.length)
            "
          >
            <template #ips>{{ lastUsedIps.join(', ') }}</template>
          </gl-sprintf>
        </div>
      </template>

      <template #cell(lifetime)="{ item: { createdAt, expiresAt } }">
        <div
          class="gl-flex gl-flex-col gl-gap-3 gl-justify-self-end @md/panel:gl-justify-self-start"
        >
          <div class="gl-flex gl-gap-2 gl-whitespace-nowrap" data-testid="field-expires">
            <gl-icon
              v-gl-tooltip
              :aria-label="s__('AccessTokens|Expires')"
              :title="s__('AccessTokens|Expires')"
              name="time-out"
            />
            <time-ago-tooltip v-if="expiresAt" :time="$options.utcExpiredDate(expiresAt)" />
            <span v-else>{{ s__('AccessTokens|Never until revoked') }}</span>
          </div>

          <div class="gl-flex gl-gap-2 gl-whitespace-nowrap" data-testid="field-created">
            <gl-icon
              v-gl-tooltip
              :aria-label="s__('AccessTokens|Created')"
              :title="s__('AccessTokens|Created')"
              name="clock"
            />
            <user-date :date="$options.resetCreatedTime(createdAt)" />
          </div>
        </div>
      </template>

      <template #cell(options)="{ item }">
        <gl-disclosure-dropdown
          v-if="item.active"
          data-testid="access-token-options"
          icon="ellipsis_v"
          :no-caret="true"
          :disabled="busy"
          category="tertiary"
          :fluid-width="true"
          :items="options(item)"
        />
      </template>
    </gl-table>
    <gl-modal
      v-model="showModal"
      :title="modalTitle"
      :action-cancel="$options.i18n.modal.actionCancel"
      :action-primary="actionPrimary"
      modal-id="token-action-modal"
      @primary="actionToken"
    >
      <gl-sprintf :message="$options.i18n.modal.message[action]">
        <template #tokenName
          ><code>{{ selectedToken && selectedToken.name }}</code></template
        >
      </gl-sprintf>
    </gl-modal>
  </div>
</template>
