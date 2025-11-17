<script>
import { GlDisclosureDropdown, GlBadge, GlSprintf } from '@gitlab/ui';
import { mapActions } from 'pinia';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import { __, s__, sprintf } from '~/locale';
import ConfirmActionModal from '~/vue_shared/components/confirm_action_modal.vue';
import { useAccessTokens } from '../../stores/access_tokens';
import TokensTable from './tokens_table.vue';
import DetailsDrawer from './details_drawer.vue';

export default {
  name: 'TokenCard',
  components: {
    CrudComponent,
    GlDisclosureDropdown,
    GlBadge,
    TokensTable,
    DetailsDrawer,
    ConfirmActionModal,
    GlSprintf,
  },
  inject: ['accessTokenNew'],
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
  data() {
    return {
      selectedToken: null,
      confirmModalProps: null,
    };
  },
  computed: {
    newTokenDropdownItems() {
      return [
        {
          text: s__('AccessTokens|Fine-grained token'),
          href: this.accessTokenNew,
          description: s__(
            'AccessTokens|Limit scope to specific groups and projects and fine-grained permissions to resources.',
          ),
          badge: __('Beta'),
        },
        {
          text: s__('AccessTokens|Broad-access token'),
          href: this.accessTokenNew,
          description: s__(
            'AccessTokens|Scoped to all groups and projects with broad permissions to resources.',
          ),
        },
      ];
    },
    modalTitle() {
      return sprintf(this.confirmModalProps.title, {
        tokenName: this.confirmModalProps.token.name,
      });
    },
  },
  methods: {
    ...mapActions(useAccessTokens, ['rotateToken', 'revokeToken']),
    showRotateDialog(token) {
      this.confirmModalProps = {
        token,
        title: s__("AccessTokens|Rotate the token '%{tokenName}'?"),
        actionText: s__('AccessTokens|Rotate'),
        message: s__(
          'AccessTokens|Are you sure you want to rotate the token %{tokenName}? This action cannot be undone. Any tools that rely on this access token will stop working.',
        ),
        actionFn: async () => {
          await this.rotateToken(token.id, token.expiresAt);
          // Close the token details drawer if it was open. The token doesn't update automatically after the rotation, so
          // the user needs to re-open the drawer to see the updated details.
          this.selectedToken = null;
        },
      };
    },
    showRevokeDialog(token) {
      this.confirmModalProps = {
        token,
        title: s__("AccessTokens|Revoke the token '%{tokenName}'?"),
        actionText: s__('AccessTokens|Revoke'),
        message: s__(
          'AccessTokens|Are you sure you want to revoke the token %{tokenName}? This action cannot be undone. Any tools that rely on this access token will stop working.',
        ),
        actionFn: async () => {
          await this.revokeToken(token.id);
          // Close the token details drawer if it was open. The token doesn't update automatically after the revoke, so the
          // user needs to re-open the drawer to see the updated details.
          this.selectedToken = null;
        },
      };
    },
  },
};
</script>

<template>
  <crud-component :title="s__('AccessTokens|Personal access tokens')">
    <template #actions>
      <gl-disclosure-dropdown
        :items="newTokenDropdownItems"
        :toggle-text="s__('AccessTokens|Generate token')"
        placement="bottom-end"
        fluid-width
      >
        <template #list-item="{ item }">
          <div class="gl-mx-3 gl-w-34">
            <div class="gl-font-bold">
              {{ item.text }}
              <gl-badge v-if="item.badge" class="gl-ml-2" variant="info">
                {{ item.badge }}
              </gl-badge>
            </div>
            <div class="gl-mt-2 gl-text-subtle">{{ item.description }}</div>
          </div>
        </template>
      </gl-disclosure-dropdown>
    </template>

    <tokens-table
      :tokens="tokens"
      :loading="loading"
      @select="selectedToken = $event"
      @rotate="showRotateDialog"
      @revoke="showRevokeDialog"
    />
    <details-drawer
      :token="selectedToken"
      @rotate="showRotateDialog"
      @revoke="showRevokeDialog"
      @close="selectedToken = null"
    />

    <confirm-action-modal
      v-if="confirmModalProps"
      modal-id="token-action-confirm-modal"
      :title="modalTitle"
      :action-fn="confirmModalProps.actionFn"
      :action-text="confirmModalProps.actionText"
      @close="confirmModalProps = null"
    >
      <gl-sprintf :message="confirmModalProps.message">
        <template #tokenName>
          <code>{{ confirmModalProps.token.name }}</code>
        </template>
      </gl-sprintf>
    </confirm-action-modal>
  </crud-component>
</template>
