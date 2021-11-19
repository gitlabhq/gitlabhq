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
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import CodeBlock from '~/vue_shared/components/code_block.vue';
import { generateAgentRegistrationCommand } from '../clusters_util';
import { INSTALL_AGENT_MODAL_ID, I18N_AGENT_MODAL, KAS_DISABLED_ERROR } from '../constants';
import { addAgentToStore, addAgentConfigToStore } from '../graphql/cache_update';
import createAgent from '../graphql/mutations/create_agent.mutation.graphql';
import createAgentToken from '../graphql/mutations/create_agent_token.mutation.graphql';
import getAgentsQuery from '../graphql/queries/get_agents.query.graphql';
import agentConfigurations from '../graphql/queries/agent_configurations.query.graphql';
import AvailableAgentsDropdown from './available_agents_dropdown.vue';

export default {
  modalId: INSTALL_AGENT_MODAL_ID,
  components: {
    AvailableAgentsDropdown,
    ClipboardButton,
    CodeBlock,
    GlAlert,
    GlButton,
    GlFormGroup,
    GlFormInputGroup,
    GlLink,
    GlModal,
    GlSprintf,
  },
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
      return !this.registered && !this.registering && this.isRegisterModal;
    },
    agentRegistrationCommand() {
      return generateAgentRegistrationCommand(this.agentToken, this.kasAddress);
    },
    basicInstallPath() {
      return helpPagePath('user/clusters/agent/install/index', {
        anchor: 'install-the-agent-into-the-cluster',
      });
    },
    advancedInstallPath() {
      return helpPagePath('user/clusters/agent/install/index', { anchor: 'advanced-installation' });
    },
    enableKasPath() {
      return helpPagePath('administration/clusters/kas');
    },
    getAgentsQueryVariables() {
      return {
        defaultBranchName: this.defaultBranchName,
        first: this.maxAgents,
        last: null,
        projectPath: this.projectPath,
      };
    },
    installAgentPath() {
      return helpPagePath('user/clusters/agent/index', {
        anchor: 'define-a-configuration-repository',
      });
    },
    i18n() {
      return I18N_AGENT_MODAL[this.modalType];
    },
    repositoryPath() {
      return `/${this.projectPath}`;
    },
    modalType() {
      return !this.availableAgents?.length && !this.registered ? 'install' : 'register';
    },
    modalSize() {
      return this.isInstallModal ? 'sm' : 'md';
    },
    isInstallModal() {
      return this.modalType === 'install';
    },
    isRegisterModal() {
      return this.modalType === 'register';
    },
  },
  methods: {
    setAgentName(name) {
      this.agentName = name;
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
  >
    <template v-if="isRegisterModal">
      <template v-if="!registered">
        <p>
          <strong>{{ i18n.selectAgentTitle }}</strong>
        </p>

        <p class="gl-mb-0">{{ i18n.selectAgentBody }}</p>
        <p>
          <gl-link :href="basicInstallPath" target="_blank"> {{ i18n.learnMoreLink }}</gl-link>
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
              <gl-link :href="basicInstallPath" target="_blank"> {{ content }}</gl-link>
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
              <clipboard-button :text="agentToken" :title="i18n.copyToken" />
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
              <gl-link :href="advancedInstallPath" target="_blank"> {{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </p>
      </template>
    </template>

    <template v-else>
      <div class="gl-text-center gl-mb-5">
        <img :alt="i18n.altText" :src="emptyStateImage" height="100" />
      </div>
      <p>{{ i18n.modalBody }}</p>

      <p v-if="kasDisabled">
        <gl-sprintf :message="i18n.enableKasText">
          <template #link="{ content }">
            <gl-link :href="enableKasPath"> {{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </p>

      <p class="gl-mb-0">
        <gl-link :href="installAgentPath">
          {{ i18n.docsLinkText }}
        </gl-link>
      </p>
    </template>

    <template #modal-footer>
      <gl-button v-if="canCancel" @click="closeModal">{{ i18n.cancel }} </gl-button>

      <gl-button v-if="registered" variant="confirm" category="primary" @click="closeModal"
        >{{ i18n.close }}
      </gl-button>

      <gl-button
        v-else-if="isRegisterModal"
        :disabled="!nextButtonDisabled"
        variant="confirm"
        category="primary"
        @click="registerAgent"
        >{{ i18n.registerAgentButton }}
      </gl-button>

      <gl-button
        v-if="isInstallModal"
        :href="repositoryPath"
        variant="confirm"
        category="secondary"
        data-testid="agent-secondary-button"
        >{{ i18n.secondaryButton }}
      </gl-button>

      <gl-button v-if="isInstallModal" variant="confirm" category="primary" @click="closeModal"
        >{{ i18n.done }}
      </gl-button>
    </template>
  </gl-modal>
</template>
