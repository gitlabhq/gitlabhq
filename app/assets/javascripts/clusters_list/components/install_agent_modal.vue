<script>
import {
  GlAlert,
  GlButton,
  GlFormGroup,
  GlFormInputGroup,
  GlLink,
  GlModal,
  GlSprintf,
} from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';
import CodeBlock from '~/vue_shared/components/code_block.vue';
import Tracking from '~/tracking';
import { generateAgentRegistrationCommand } from '../clusters_util';
import {
  INSTALL_AGENT_MODAL_ID,
  I18N_AGENT_MODAL,
  KAS_DISABLED_ERROR,
  EVENT_LABEL_MODAL,
  EVENT_ACTIONS_OPEN,
  EVENT_ACTIONS_SELECT,
  EVENT_ACTIONS_CLICK,
  MODAL_TYPE_EMPTY,
  MODAL_TYPE_REGISTER,
} from '../constants';
import { addAgentToStore, addAgentConfigToStore } from '../graphql/cache_update';
import createAgent from '../graphql/mutations/create_agent.mutation.graphql';
import createAgentToken from '../graphql/mutations/create_agent_token.mutation.graphql';
import getAgentsQuery from '../graphql/queries/get_agents.query.graphql';
import agentConfigurations from '../graphql/queries/agent_configurations.query.graphql';
import AvailableAgentsDropdown from './available_agents_dropdown.vue';

const trackingMixin = Tracking.mixin({ label: EVENT_LABEL_MODAL });

export default {
  modalId: INSTALL_AGENT_MODAL_ID,
  EVENT_ACTIONS_OPEN,
  EVENT_ACTIONS_CLICK,
  EVENT_LABEL_MODAL,
  basicInstallPath: helpPagePath('user/clusters/agent/install/index', {
    anchor: 'install-the-agent-into-the-cluster',
  }),
  advancedInstallPath: helpPagePath('user/clusters/agent/install/index', {
    anchor: 'advanced-installation',
  }),
  enableKasPath: helpPagePath('administration/clusters/kas'),
  installAgentPath: helpPagePath('user/clusters/agent/install/index'),
  registerAgentPath: helpPagePath('user/clusters/agent/install/index', {
    anchor: 'register-an-agent-with-gitlab',
  }),
  components: {
    AvailableAgentsDropdown,
    CodeBlock,
    GlAlert,
    GlButton,
    GlFormGroup,
    GlFormInputGroup,
    GlLink,
    GlModal,
    GlSprintf,
    ModalCopyButton,
  },
  mixins: [trackingMixin],
  inject: ['projectPath', 'kasAddress', 'emptyStateImage'],
  props: {
    defaultBranchName: {
      default: '.noBranch',
      required: false,
      type: String,
    },
    maxAgents: {
      required: true,
      type: Number,
    },
  },
  apollo: {
    agents: {
      query: agentConfigurations,
      variables() {
        return {
          projectPath: this.projectPath,
        };
      },
      update(data) {
        this.populateAvailableAgents(data);
      },
      error(error) {
        this.kasDisabled = error?.message?.indexOf(KAS_DISABLED_ERROR) >= 0;
      },
    },
  },
  data() {
    return {
      registering: false,
      agentName: null,
      agentToken: null,
      error: null,
      clusterAgent: null,
      availableAgents: [],
      kasDisabled: false,
    };
  },
  computed: {
    registered() {
      return Boolean(this.agentToken);
    },
    nextButtonDisabled() {
      return !this.registering && this.agentName !== null;
    },
    canCancel() {
      return !this.registered && !this.registering && this.isAgentRegistrationModal;
    },
    agentRegistrationCommand() {
      return generateAgentRegistrationCommand(this.agentToken, this.kasAddress);
    },
    getAgentsQueryVariables() {
      return {
        defaultBranchName: this.defaultBranchName,
        first: this.maxAgents,
        last: null,
        projectPath: this.projectPath,
      };
    },
    i18n() {
      return I18N_AGENT_MODAL[this.modalType];
    },
    repositoryPath() {
      return `/${this.projectPath}`;
    },
    modalType() {
      return !this.availableAgents?.length && !this.registered
        ? MODAL_TYPE_EMPTY
        : MODAL_TYPE_REGISTER;
    },
    modalSize() {
      return this.isEmptyStateModal ? 'sm' : 'md';
    },
    isEmptyStateModal() {
      return this.modalType === MODAL_TYPE_EMPTY;
    },
    isAgentRegistrationModal() {
      return this.modalType === MODAL_TYPE_REGISTER;
    },
    isKasEnabledInEmptyStateModal() {
      return this.isEmptyStateModal && !this.kasDisabled;
    },
  },
  methods: {
    setAgentName(name) {
      this.agentName = name;
      this.track(EVENT_ACTIONS_SELECT);
    },
    closeModal() {
      this.$refs.modal.hide();
    },
    resetModal() {
      this.registering = false;
      this.agentName = null;
      this.agentToken = null;
      this.clusterAgent = null;
      this.error = null;
    },
    populateAvailableAgents(data) {
      const installedAgents = data?.project?.clusterAgents?.nodes.map((agent) => agent.name) ?? [];
      const configuredAgents =
        data?.project?.agentConfigurations?.nodes.map((config) => config.agentName) ?? [];

      this.availableAgents = configuredAgents.filter((agent) => !installedAgents.includes(agent));
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
          update: (store, { data: { createClusterAgent } }) => {
            addAgentToStore(
              store,
              createClusterAgent,
              getAgentsQuery,
              this.getAgentsQueryVariables,
            );
          },
        })
        .then(({ data: { createClusterAgent } }) => {
          return createClusterAgent;
        });
    },
    createAgentTokenMutation(agendId) {
      return this.$apollo
        .mutate({
          mutation: createAgentToken,
          variables: {
            input: {
              clusterAgentId: agendId,
              name: this.agentName,
            },
          },
          update: (store, { data: { clusterAgentTokenCreate } }) => {
            addAgentConfigToStore(
              store,
              clusterAgentTokenCreate,
              this.clusterAgent,
              agentConfigurations,
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
          this.error = this.i18n.unknownError;
        }
      } finally {
        this.registering = false;
      }
    },
  },
};
</script>

<template>
  <gl-modal
    ref="modal"
    :modal-id="$options.modalId"
    :title="i18n.modalTitle"
    :size="modalSize"
    static
    lazy
    @hidden="resetModal"
    @show="track($options.EVENT_ACTIONS_OPEN, { property: modalType })"
  >
    <template v-if="isAgentRegistrationModal">
      <template v-if="!registered">
        <p>
          <strong>{{ i18n.selectAgentTitle }}</strong>
        </p>

        <p class="gl-mb-0">{{ i18n.selectAgentBody }}</p>
        <p>
          <gl-link :href="$options.registerAgentPath"> {{ i18n.learnMoreLink }}</gl-link>
        </p>

        <form>
          <gl-form-group label-for="agent-name">
            <available-agents-dropdown
              class="gl-w-70p"
              :is-registering="registering"
              :available-agents="availableAgents"
              @agentSelected="setAgentName"
            />
          </gl-form-group>
        </form>

        <p v-if="error">
          <gl-alert :title="i18n.registrationErrorTitle" variant="danger" :dismissible="false">
            {{ error }}
          </gl-alert>
        </p>
      </template>

      <template v-else>
        <p>
          <strong>{{ i18n.tokenTitle }}</strong>
        </p>

        <p>
          <gl-sprintf :message="i18n.tokenBody">
            <template #link="{ content }">
              <gl-link :href="$options.basicInstallPath" target="_blank"> {{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </p>

        <p>
          <gl-alert :title="i18n.tokenSingleUseWarningTitle" variant="warning" :dismissible="false">
            {{ i18n.tokenSingleUseWarningBody }}
          </gl-alert>
        </p>

        <p>
          <gl-form-input-group readonly :value="agentToken" :select-on-click="true">
            <template #append>
              <modal-copy-button
                :text="agentToken"
                :title="i18n.copyToken"
                :modal-id="$options.modalId"
              />
            </template>
          </gl-form-input-group>
        </p>

        <p>
          <strong>{{ i18n.basicInstallTitle }}</strong>
        </p>

        <p>
          {{ i18n.basicInstallBody }}
        </p>

        <p>
          <code-block :code="agentRegistrationCommand" />
        </p>

        <p>
          <strong>{{ i18n.advancedInstallTitle }}</strong>
        </p>

        <p>
          <gl-sprintf :message="i18n.advancedInstallBody">
            <template #link="{ content }">
              <gl-link :href="$options.advancedInstallPath" target="_blank"> {{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </p>
      </template>
    </template>

    <template v-else>
      <div class="gl-text-center gl-mb-5">
        <img :alt="i18n.altText" :src="emptyStateImage" height="100" />
      </div>

      <p v-if="kasDisabled">
        <gl-sprintf :message="i18n.enableKasText">
          <template #link="{ content }">
            <gl-link :href="$options.enableKasPath">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </p>

      <p v-else>
        <gl-sprintf :message="i18n.modalBody">
          <template #link="{ content }">
            <gl-link :href="$options.installAgentPath">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </p>
    </template>

    <template #modal-footer>
      <gl-button
        v-if="registered"
        variant="confirm"
        category="primary"
        :data-track-action="$options.EVENT_ACTIONS_CLICK"
        :data-track-label="$options.EVENT_LABEL_MODAL"
        data-track-property="close"
        @click="closeModal"
        >{{ i18n.close }}
      </gl-button>

      <gl-button
        v-else-if="isAgentRegistrationModal"
        :disabled="!nextButtonDisabled"
        variant="confirm"
        category="primary"
        :data-track-action="$options.EVENT_ACTIONS_CLICK"
        :data-track-label="$options.EVENT_LABEL_MODAL"
        data-track-property="register"
        @click="registerAgent"
        >{{ i18n.registerAgentButton }}
      </gl-button>

      <gl-button
        v-if="canCancel"
        :data-track-action="$options.EVENT_ACTIONS_CLICK"
        :data-track-label="$options.EVENT_LABEL_MODAL"
        data-track-property="cancel"
        @click="closeModal"
        >{{ i18n.cancel }}
      </gl-button>

      <gl-button
        v-if="isEmptyStateModal"
        variant="confirm"
        category="secondary"
        :data-track-action="$options.EVENT_ACTIONS_CLICK"
        :data-track-label="$options.EVENT_LABEL_MODAL"
        data-track-property="done"
        @click="closeModal"
        >{{ i18n.done }}
      </gl-button>

      <gl-button
        v-if="isKasEnabledInEmptyStateModal"
        :href="repositoryPath"
        variant="confirm"
        category="primary"
        data-testid="agent-primary-button"
        >{{ i18n.primaryButton }}
      </gl-button>
    </template>
  </gl-modal>
</template>
