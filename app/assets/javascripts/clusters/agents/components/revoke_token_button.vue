<script>
import {
  GlButton,
  GlModalDirective,
  GlTooltip,
  GlModal,
  GlFormGroup,
  GlFormInput,
  GlSprintf,
} from '@gitlab/ui';
import { s__, __, sprintf } from '~/locale';
import { REVOKE_TOKEN_MODAL_ID } from '../constants';
import revokeAgentToken from '../graphql/mutations/revoke_token.mutation.graphql';
import getClusterAgentQuery from '../graphql/queries/get_cluster_agent.query.graphql';
import { removeTokenFromStore } from '../graphql/cache_update';

export default {
  components: {
    GlButton,
    GlTooltip,
    GlModal,
    GlFormGroup,
    GlFormInput,
    GlSprintf,
  },
  directives: {
    GlModalDirective,
  },
  inject: ['agentName', 'projectPath', 'canAdminCluster'],
  props: {
    token: {
      required: true,
      type: Object,
      validator: (value) => ['id', 'name'].every((prop) => value[prop]),
    },
    cursor: {
      required: true,
      type: Object,
    },
  },
  i18n: {
    revokeButton: s__('ClusterAgents|Revoke token'),
    dropdownDisabledHint: s__(
      'ClusterAgents|Requires a Maintainer or greater role to perform this action',
    ),
    modalTitle: s__('ClusterAgents|Revoke access token?'),
    modalBody: s__(
      'ClusterAgents|Are you sure you want to revoke this token? You cannot undo this action.',
    ),
    modalInputLabel: s__('ClusterAgents|To revoke the token, type %{name} to confirm:'),
    modalCancel: __('Cancel'),
    successMessage: s__('ClusterAgents|%{name} successfully revoked'),
    defaultError: __('An error occurred. Please try again.'),
  },
  data() {
    return {
      loading: false,
      error: null,
      revokeConfirmText: null,
      tokenName: null,
      variables: {
        agentName: this.agentName,
        projectPath: this.projectPath,
        ...this.cursor,
      },
    };
  },
  computed: {
    revokeBtnDisabled() {
      return this.loading || !this.canAdminCluster;
    },
    modalId() {
      return sprintf(REVOKE_TOKEN_MODAL_ID, {
        tokenName: this.token.name,
      });
    },
    primaryModalProps() {
      return {
        text: this.$options.i18n.revokeButton,
        attributes: {
          disabled: this.loading || this.disableModalSubmit,
          loading: this.loading,
          variant: 'danger',
        },
      };
    },
    cancelModalProps() {
      return {
        text: this.$options.i18n.modalCancel,
        attributes: {},
      };
    },
    disableModalSubmit() {
      return this.revokeConfirmText !== this.token.name;
    },
  },
  methods: {
    async revokeToken() {
      if (this.disableModalSubmit || this.loading) {
        return;
      }

      this.loading = true;
      this.error = null;
      this.tokenName = this.token.name;

      try {
        const { errors } = await this.revokeTokenMutation();

        if (errors.length) {
          throw new Error(errors[0]);
        }
      } catch (error) {
        this.error = error?.message || this.$options.i18n.defaultError;
      } finally {
        this.loading = false;
        const successMessage = sprintf(this.$options.i18n.successMessage, {
          name: this.tokenName,
        });

        this.$toast.show(this.error || successMessage);

        this.hideModal();
      }
    },
    revokeTokenMutation() {
      return this.$apollo
        .mutate({
          mutation: revokeAgentToken,
          variables: {
            input: {
              id: this.token.id,
            },
          },
          update: (store) => {
            removeTokenFromStore(store, this.token, getClusterAgentQuery, this.variables);
          },
        })

        .then(({ data: { clusterAgentTokenRevoke } }) => {
          return clusterAgentTokenRevoke;
        });
    },
    resetModal() {
      this.loading = false;
      this.error = null;
      this.revokeConfirmText = null;
    },
    hideModal() {
      this.resetModal();
      this.$refs.modal?.hide();
    },
  },
};
</script>

<template>
  <div>
    <div ref="revokeToken" class="gl-inline-block">
      <gl-button
        v-gl-modal-directive="modalId"
        icon="remove"
        category="secondary"
        variant="danger"
        :disabled="revokeBtnDisabled"
        :title="$options.i18n.revokeButton"
        :aria-label="$options.i18n.revokeButton"
      />

      <gl-tooltip
        v-if="!canAdminCluster"
        :target="() => $refs.revokeToken"
        :title="$options.i18n.dropdownDisabledHint"
      />
    </div>

    <gl-modal
      ref="modal"
      :modal-id="modalId"
      :title="$options.i18n.modalTitle"
      :action-primary="primaryModalProps"
      :action-cancel="cancelModalProps"
      size="sm"
      @primary="revokeToken"
      @hide="hideModal"
    >
      <p>{{ $options.i18n.modalBody }}</p>

      <gl-form-group>
        <template #label>
          <gl-sprintf :message="$options.i18n.modalInputLabel">
            <template #name>
              <code>{{ token.name }}</code>
            </template>
          </gl-sprintf>
        </template>
        <gl-form-input v-model="revokeConfirmText" @keydown.enter="revokeToken" />
      </gl-form-group>
    </gl-modal>
  </div>
</template>
