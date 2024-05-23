<script>
import { GlButton, GlModal, GlFormGroup, GlFormInput, GlFormTextarea, GlAlert } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import Tracking from '~/tracking';
import AgentToken from '~/clusters_list/components/agent_token.vue';
import {
  CREATE_TOKEN_MODAL,
  EVENT_LABEL_MODAL,
  EVENT_ACTIONS_OPEN,
  EVENT_ACTIONS_CLICK,
  TOKEN_NAME_LIMIT,
} from '../constants';
import createNewAgentToken from '../graphql/mutations/create_new_agent_token.mutation.graphql';
import getClusterAgentQuery from '../graphql/queries/get_cluster_agent.query.graphql';
import { addAgentTokenToStore } from '../graphql/cache_update';

const trackingMixin = Tracking.mixin({ label: EVENT_LABEL_MODAL });

export default {
  components: {
    AgentToken,
    GlButton,
    GlModal,
    GlFormGroup,
    GlFormInput,
    GlFormTextarea,
    GlAlert,
  },
  mixins: [trackingMixin],
  inject: ['agentName', 'projectPath'],
  props: {
    clusterAgentId: {
      required: true,
      type: String,
    },
    cursor: {
      required: true,
      type: Object,
    },
  },
  modalId: CREATE_TOKEN_MODAL,
  EVENT_ACTIONS_OPEN,
  EVENT_ACTIONS_CLICK,
  EVENT_LABEL_MODAL,
  TOKEN_NAME_LIMIT,
  i18n: {
    createTokenButton: s__('ClusterAgents|Create token'),
    modalTitle: s__('ClusterAgents|Create agent access token'),
    unknownError: s__('ClusterAgents|An unknown error occurred. Please try again.'),
    errorTitle: s__('ClusterAgents|Failed to create a token'),
    modalCancel: __('Cancel'),
    modalClose: __('Close'),
    tokenNameLabel: __('Name'),
    tokenDescriptionLabel: __('Description (optional)'),
  },
  data() {
    return {
      token: {
        name: null,
        description: null,
      },
      agentToken: null,
      error: null,
      loading: false,
      variables: {
        agentName: this.agentName,
        projectPath: this.projectPath,
        ...this.cursor,
      },
    };
  },
  computed: {
    modalBtnDisabled() {
      return this.loading || !this.hasTokenName;
    },
    hasTokenName() {
      return Boolean(this.token.name?.length);
    },
  },
  methods: {
    async createToken() {
      this.loading = true;
      this.error = null;

      try {
        const { errors: tokenErrors, secret } = await this.createAgentTokenMutation();

        if (tokenErrors?.length > 0) {
          throw new Error(tokenErrors[0]);
        }
        this.agentToken = secret;
      } catch (error) {
        this.error = error ? error.message : this.$options.i18n.unknownError;
      } finally {
        this.loading = false;
      }
    },
    resetModal() {
      this.agentToken = null;
      this.token.name = null;
      this.token.description = null;
      this.error = null;
    },
    closeModal() {
      this.$refs.modal.hide();
    },
    createAgentTokenMutation() {
      return this.$apollo
        .mutate({
          mutation: createNewAgentToken,
          variables: {
            input: {
              clusterAgentId: this.clusterAgentId,
              name: this.token.name,
              description: this.token.description,
            },
          },
          update: (store, { data: { clusterAgentTokenCreate } }) => {
            addAgentTokenToStore(
              store,
              clusterAgentTokenCreate,
              getClusterAgentQuery,
              this.variables,
            );
          },
        })
        .then(({ data: { clusterAgentTokenCreate } }) => clusterAgentTokenCreate);
    },
  },
};
</script>

<template>
  <gl-modal
    ref="modal"
    :modal-id="$options.modalId"
    :title="$options.i18n.modalTitle"
    static
    lazy
    @hidden="resetModal"
    @show="track($options.EVENT_ACTIONS_OPEN)"
  >
    <gl-alert
      v-if="error"
      :title="$options.i18n.errorTitle"
      :dismissible="false"
      variant="danger"
      class="gl-mb-5"
    >
      {{ error }}
    </gl-alert>

    <template v-if="!agentToken">
      <gl-form-group :label="$options.i18n.tokenNameLabel" label-for="token-name">
        <gl-form-input
          id="token-name"
          v-model="token.name"
          :max-length="$options.TOKEN_NAME_LIMIT"
          :disabled="loading"
          required
        />
      </gl-form-group>

      <gl-form-group :label="$options.i18n.tokenDescriptionLabel" label-for="token-description">
        <gl-form-textarea
          id="token-description"
          v-model="token.description"
          :disabled="loading"
          no-resize
          name="description"
        />
      </gl-form-group>
    </template>

    <agent-token
      v-else
      :agent-name="agentName"
      :agent-token="agentToken"
      :modal-id="$options.modalId"
    />

    <template #modal-footer>
      <gl-button
        v-if="!agentToken && !loading"
        :data-track-action="$options.EVENT_ACTIONS_CLICK"
        :data-track-label="$options.EVENT_LABEL_MODAL"
        data-track-property="close"
        data-testid="agent-token-close-button"
        @click="closeModal"
        >{{ $options.i18n.modalCancel }}
      </gl-button>

      <gl-button
        v-if="!agentToken"
        :disabled="modalBtnDisabled"
        :loading="loading"
        :data-track-action="$options.EVENT_ACTIONS_CLICK"
        :data-track-label="$options.EVENT_LABEL_MODAL"
        data-track-property="create-token"
        variant="confirm"
        type="submit"
        @click="createToken"
        >{{ $options.i18n.createTokenButton }}
      </gl-button>

      <gl-button
        v-else
        :data-track-action="$options.EVENT_ACTIONS_CLICK"
        :data-track-label="$options.EVENT_LABEL_MODAL"
        data-track-property="close"
        variant="confirm"
        @click="closeModal"
        >{{ $options.i18n.modalClose }}
      </gl-button>
    </template>
  </gl-modal>
</template>
