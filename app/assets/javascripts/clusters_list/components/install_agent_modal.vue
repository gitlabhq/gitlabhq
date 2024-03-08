<script>
import { GlAlert, GlButton, GlFormGroup, GlLink, GlModal, GlSprintf } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import Tracking from '~/tracking';
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
import { addAgentConfigToStore } from '../graphql/cache_update';
import createAgent from '../graphql/mutations/create_agent.mutation.graphql';
import createAgentToken from '../graphql/mutations/create_agent_token.mutation.graphql';
import agentConfigurations from '../graphql/queries/agent_configurations.query.graphql';
import AvailableAgentsDropdown from './available_agents_dropdown.vue';
import AgentToken from './agent_token.vue';

const trackingMixin = Tracking.mixin({ label: EVENT_LABEL_MODAL });

export default {
  modalId: INSTALL_AGENT_MODAL_ID,
  i18n: I18N_AGENT_MODAL,
  EVENT_ACTIONS_OPEN,
  EVENT_ACTIONS_CLICK,
  EVENT_LABEL_MODAL,
  enableKasPath: helpPagePath('administration/clusters/kas'),
  registerAgentPath: helpPagePath('user/clusters/agent/install/index', {
    anchor: 'register-the-agent-with-gitlab',
  }),
  terraformDocsLink:
    'https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs/resources/cluster_agent_token',
  minAgentsForTerraform: 10,
  maxAgents: 100,
  components: {
    AvailableAgentsDropdown,
    AgentToken,
    GlAlert,
    GlButton,
    GlFormGroup,
    GlLink,
    GlModal,
    GlSprintf,
  },
  mixins: [trackingMixin],
  inject: ['projectPath', 'emptyStateImage'],
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
      configuredAgentsCount: 0,
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
      return !this.registered && !this.registering && !this.kasDisabled;
    },
    canRegister() {
      return !this.registered && !this.kasDisabled;
    },
    getAgentsQueryVariables() {
      return {
        defaultBranchName: this.defaultBranchName,
        first: this.maxAgents,
        last: null,
        projectPath: this.projectPath,
      };
    },

    repositoryPath() {
      return `/${this.projectPath}`;
    },
    modalType() {
      return this.kasDisabled ? MODAL_TYPE_EMPTY : MODAL_TYPE_REGISTER;
    },
    modalSize() {
      return this.kasDisabled ? 'sm' : 'md';
    },
    showTerraformSuggestionAlert() {
      return this.configuredAgentsCount >= this.$options.minAgentsForTerraform;
    },
    showMaxAgentsAlert() {
      return this.configuredAgentsCount >= this.$options.maxAgents;
    },
  },
  methods: {
    setAgentName(name) {
      this.error = null;
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

      this.configuredAgentsCount = configuredAgents.length;
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
          this.error = this.$options.i18n.unknownError;
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
    :title="$options.i18n.modalTitle"
    :size="modalSize"
    static
    lazy
    @hidden="resetModal"
    @show="track($options.EVENT_ACTIONS_OPEN, { property: modalType })"
  >
    <template v-if="!kasDisabled">
      <template v-if="!registered">
        <p class="gl-mb-0">
          <gl-sprintf :message="$options.i18n.modalBody">
            <template #link="{ content }">
              <gl-link :href="repositoryPath">{{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </p>

        <gl-alert
          v-if="showTerraformSuggestionAlert"
          :dismissible="false"
          variant="warning"
          class="gl-my-4"
        >
          <span v-if="showMaxAgentsAlert">{{ $options.i18n.maxAgentsSupport }}</span>
          <span>
            <gl-sprintf :message="$options.i18n.useTerraformText">
              <template #link="{ content }">
                <gl-link :href="$options.terraformDocsLink">{{ content }}</gl-link>
              </template>
            </gl-sprintf>
          </span>
        </gl-alert>

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

        <p>
          <gl-link :href="$options.registerAgentPath"> {{ $options.i18n.learnMoreLink }}</gl-link>
        </p>

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

      <agent-token
        v-else
        :agent-name="agentName"
        :agent-token="agentToken"
        :modal-id="$options.modalId"
      />
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
        :disabled="!nextButtonDisabled"
        variant="confirm"
        category="primary"
        :data-track-action="$options.EVENT_ACTIONS_CLICK"
        :data-track-label="$options.EVENT_LABEL_MODAL"
        data-track-property="register"
        @click="registerAgent"
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
