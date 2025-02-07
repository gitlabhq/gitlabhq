<script>
import {
  GlAlert,
  GlButton,
  GlForm,
  GlFormGroup,
  GlFormInput,
  GlLink,
  GlModal,
  GlSprintf,
} from '@gitlab/ui';
import { cloneDeep } from 'lodash';
import { helpPagePath } from '~/helpers/help_page_helper';
import Tracking from '~/tracking';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';
import CodeBlockHighlighted from '~/vue_shared/components/code_block_highlighted.vue';
import createAgent from 'ee_else_ce/clusters_list/graphql/mutations/create_agent.mutation.graphql';
import getAgentsQuery from 'ee_else_ce/clusters_list/graphql/queries/get_agents.query.graphql';
import {
  INSTALL_AGENT_MODAL_ID,
  I18N_AGENT_MODAL,
  EVENT_LABEL_MODAL,
  EVENT_ACTIONS_OPEN,
  EVENT_ACTIONS_CLICK,
  MODAL_TYPE_EMPTY,
  MODAL_TYPE_REGISTER,
} from '../constants';
import { addAgentConfigToStore } from '../graphql/cache_update';
import createAgentToken from '../graphql/mutations/create_agent_token.mutation.graphql';
import AgentToken from './agent_token.vue';

const trackingMixin = Tracking.mixin({ label: EVENT_LABEL_MODAL });

export default {
  modalId: INSTALL_AGENT_MODAL_ID,
  i18n: I18N_AGENT_MODAL,
  EVENT_ACTIONS_OPEN,
  EVENT_ACTIONS_CLICK,
  EVENT_LABEL_MODAL,
  glabCommand: 'glab cluster agent bootstrap <agent-name>',
  enableKasPath: helpPagePath('administration/clusters/kas'),
  registerAgentPath: helpPagePath('user/clusters/agent/install/_index', {
    anchor: 'register-the-agent-with-gitlab',
  }),
  bootstrapAgentWithFluxHelpPath: helpPagePath('user/clusters/agent/install/_index', {
    anchor: 'bootstrap-the-agent-with-flux-support-recommended',
  }),
  commandLanguage: 'shell',
  components: {
    AgentToken,
    GlAlert,
    GlButton,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlLink,
    GlModal,
    GlSprintf,
    ModalCopyButton,
    CodeBlockHighlighted,
  },
  mixins: [trackingMixin],
  inject: ['projectPath', 'emptyStateImage'],
  props: {
    kasDisabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      registering: false,
      agentName: null,
      agentToken: null,
      error: null,
      clusterAgent: null,
      isValidated: false,
      glabCommand: this.$options.glabCommand,
    };
  },
  computed: {
    registered() {
      return Boolean(this.agentToken);
    },
    canCancel() {
      return !this.registered && !this.registering && !this.kasDisabled;
    },
    canRegister() {
      return !this.registered && !this.kasDisabled;
    },
    modalType() {
      return this.kasDisabled ? MODAL_TYPE_EMPTY : MODAL_TYPE_REGISTER;
    },
    modalSize() {
      return this.kasDisabled ? 'sm' : 'md';
    },
    agentNameValid() {
      if (!this.isValidated) {
        return true;
      }
      return Boolean(this.agentName?.length);
    },
  },
  methods: {
    closeModal() {
      this.$refs.modal.hide();
    },
    resetModal() {
      this.registering = false;
      this.agentName = null;
      this.agentToken = null;
      this.clusterAgent = null;
      this.error = null;
      this.glabCommand = this.$options.glabCommand;
    },
    createAgentMutation() {
      return this.$apollo
        .mutate({
          mutation: createAgent,
          variables: {
            input: {
              name: this.agentName,
              projectPath: this.projectPath,
            },
          },
        })
        .then(({ data: { createClusterAgent } }) => {
          return createClusterAgent;
        });
    },
    createAgentTokenMutation(agentId) {
      return this.$apollo
        .mutate({
          mutation: createAgentToken,
          variables: {
            input: {
              clusterAgentId: agentId,
              name: this.agentName,
            },
          },
          update: (store, { data: { clusterAgentTokenCreate } }) => {
            addAgentConfigToStore(
              store,
              clusterAgentTokenCreate,
              // Create a non-reactive copy of clusterAgent to prevent Vue 3 reactivity conflicts
              cloneDeep(this.clusterAgent),
              getAgentsQuery,
              {
                projectPath: this.projectPath,
              },
            );
          },
        })
        .then(({ data: { clusterAgentTokenCreate } }) => clusterAgentTokenCreate);
    },
    async registerAgent() {
      this.registering = true;
      this.error = null;

      try {
        const { errors: agentErrors, clusterAgent } = await this.createAgentMutation();

        if (agentErrors?.length > 0) {
          throw new Error(agentErrors[0]);
        }

        this.clusterAgent = clusterAgent;
        this.$emit('clusterAgentCreated', this.clusterAgent.name);

        const { errors: tokenErrors, secret } = await this.createAgentTokenMutation(
          clusterAgent.id,
        );

        if (tokenErrors?.length > 0) {
          throw new Error(tokenErrors[0]);
        }
        this.agentToken = secret;
      } catch (error) {
        if (error) {
          this.error = error.message;
        } else {
          this.error = this.$options.i18n.unknownError;
        }
      } finally {
        this.registering = false;
        this.isValidated = false;
      }
    },
    submit() {
      this.isValidated = true;
      if (!this.canRegister || !this.agentName) {
        return;
      }
      this.registerAgent();
    },
    showModalForAgent(name) {
      this.agentName = name;
      this.$refs.modal?.show();
      this.glabCommand = this.glabCommand.replace('<agent-name>', this.agentName);
    },
  },
};
</script>

<template>
  <gl-modal
    ref="modal"
    :modal-id="$options.modalId"
    :title="$options.i18n.modalTitle"
    :size="modalSize"
    static
    lazy
    @hidden="resetModal"
    @show="track($options.EVENT_ACTIONS_OPEN, { property: modalType })"
  >
    <template v-if="!kasDisabled">
      <template v-if="!registered">
        <p class="gl-mb-2 gl-font-bold">{{ $options.i18n.bootstrapWithFluxTitle }}</p>
        <p class="gl-mb-3">{{ $options.i18n.bootstrapWithFluxDescription }}</p>
        <p class="gl-mb-3 gl-flex gl-items-start">
          <code-block-highlighted
            :language="$options.commandLanguage"
            class="gl-border gl-mb-0 gl-mr-3 gl-w-full gl-px-3 gl-py-2"
            :code="glabCommand"
          />
          <modal-copy-button :text="glabCommand" :modal-id="$options.modalId" category="tertiary" />
        </p>
        <gl-sprintf :message="$options.i18n.bootstrapWithFluxOptions">
          <template #code="{ content }">
            <code>{{ content }}</code>
          </template>
        </gl-sprintf>
        <p class="gl-mb-5">
          <gl-sprintf :message="$options.i18n.bootstrapWithFluxDocs">
            <template #link="{ content }">
              <gl-link :href="$options.bootstrapAgentWithFluxHelpPath" target="_blank">{{
                content
              }}</gl-link>
            </template>
          </gl-sprintf>
        </p>

        <p class="gl-mb-2 gl-font-bold">{{ $options.i18n.registerWithUITitle }}</p>
        <p class="gl-mb-0">
          {{ $options.i18n.modalBody }}

          <gl-link :href="$options.registerAgentPath"> {{ $options.i18n.learMore }}</gl-link>
        </p>

        <gl-form @submit.prevent="submit">
          <gl-form-group :invalid-feedback="$options.i18n.requiredFieldFeedback">
            <gl-form-input
              v-model.trim="agentName"
              :placeholder="$options.i18n.agentNamePlaceholder"
              :state="agentNameValid"
              required
              data-testid="agent-name-input"
              class="gl-w-1/2"
            />
          </gl-form-group>
        </gl-form>

        <p v-if="error">
          <gl-alert
            :title="$options.i18n.registrationErrorTitle"
            variant="danger"
            :dismissible="false"
          >
            {{ error }}
          </gl-alert>
        </p>
      </template>

      <template v-else>
        <gl-alert :dismissible="false" variant="success" class="gl-mb-5">
          <gl-sprintf :message="$options.i18n.registrationSuccess">
            <template #agentName>{{ agentName }}</template>
          </gl-sprintf></gl-alert
        >
        <agent-token
          :agent-name="agentName"
          :agent-token="agentToken"
          :modal-id="$options.modalId"
        />
      </template>
    </template>

    <gl-alert v-else :dismissible="false" variant="warning">
      <gl-sprintf :message="$options.i18n.enableKasText">
        <template #link="{ content }">
          <gl-link :href="$options.enableKasPath">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </gl-alert>

    <template #modal-footer>
      <gl-button
        v-if="registered"
        variant="confirm"
        category="primary"
        :data-track-action="$options.EVENT_ACTIONS_CLICK"
        :data-track-label="$options.EVENT_LABEL_MODAL"
        data-track-property="close"
        @click="closeModal"
        >{{ $options.i18n.close }}
      </gl-button>

      <gl-button
        v-if="canCancel"
        :data-track-action="$options.EVENT_ACTIONS_CLICK"
        :data-track-label="$options.EVENT_LABEL_MODAL"
        data-track-property="cancel"
        @click="closeModal"
        >{{ $options.i18n.cancel }}
      </gl-button>

      <gl-button
        v-if="canRegister"
        variant="confirm"
        category="primary"
        :data-track-action="$options.EVENT_ACTIONS_CLICK"
        :data-track-label="$options.EVENT_LABEL_MODAL"
        data-track-property="register"
        @click="submit"
        >{{ $options.i18n.registerAgentButton }}
      </gl-button>

      <gl-button
        v-if="kasDisabled"
        :data-track-action="$options.EVENT_ACTIONS_CLICK"
        :data-track-label="$options.EVENT_LABEL_MODAL"
        data-track-property="done"
        @click="closeModal"
        >{{ $options.i18n.close }}
      </gl-button>
    </template>
  </gl-modal>
</template>
