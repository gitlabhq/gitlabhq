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
import { INSTALL_AGENT_MODAL_ID, I18N_INSTALL_AGENT_MODAL } from '../constants';
import { addAgentToStore } from '../graphql/cache_update';
import createAgent from '../graphql/mutations/create_agent.mutation.graphql';
import createAgentToken from '../graphql/mutations/create_agent_token.mutation.graphql';
import getAgentsQuery from '../graphql/queries/get_agents.query.graphql';
import AvailableAgentsDropdown from './available_agents_dropdown.vue';

export default {
  modalId: INSTALL_AGENT_MODAL_ID,
  i18n: I18N_INSTALL_AGENT_MODAL,
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
  inject: ['projectPath', 'kasAddress'],
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
  data() {
    return {
      registering: false,
      agentName: null,
      agentToken: null,
      error: null,
      clusterAgent: null,
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
      return !this.registered && !this.registering;
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
    getAgentsQueryVariables() {
      return {
        defaultBranchName: this.defaultBranchName,
        first: this.maxAgents,
        last: null,
        projectPath: this.projectPath,
      };
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
      this.error = null;
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
        .then(({ data: { createClusterAgent } }) => createClusterAgent);
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
    static
    lazy
    @hidden="resetModal"
  >
    <template v-if="!registered">
      <p>
        <strong>{{ $options.i18n.selectAgentTitle }}</strong>
      </p>

      <p>
        <gl-sprintf :message="$options.i18n.selectAgentBody">
          <template #link="{ content }">
            <gl-link :href="basicInstallPath" target="_blank"> {{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </p>

      <form>
        <gl-form-group label-for="agent-name">
          <available-agents-dropdown
            class="gl-w-70p"
            :is-registering="registering"
            @agentSelected="setAgentName"
          />
        </gl-form-group>
      </form>

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
      <p>
        <strong>{{ $options.i18n.tokenTitle }}</strong>
      </p>

      <p>
        <gl-sprintf :message="$options.i18n.tokenBody">
          <template #link="{ content }">
            <gl-link :href="basicInstallPath" target="_blank"> {{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </p>

      <p>
        <gl-alert
          :title="$options.i18n.tokenSingleUseWarningTitle"
          variant="warning"
          :dismissible="false"
        >
          {{ $options.i18n.tokenSingleUseWarningBody }}
        </gl-alert>
      </p>

      <p>
        <gl-form-input-group readonly :value="agentToken" :select-on-click="true">
          <template #append>
            <clipboard-button :text="agentToken" :title="$options.i18n.copyToken" />
          </template>
        </gl-form-input-group>
      </p>

      <p>
        <strong>{{ $options.i18n.basicInstallTitle }}</strong>
      </p>

      <p>
        {{ $options.i18n.basicInstallBody }}
      </p>

      <p>
        <code-block :code="agentRegistrationCommand" />
      </p>

      <p>
        <strong>{{ $options.i18n.advancedInstallTitle }}</strong>
      </p>

      <p>
        <gl-sprintf :message="$options.i18n.advancedInstallBody">
          <template #link="{ content }">
            <gl-link :href="advancedInstallPath" target="_blank"> {{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </p>
    </template>

    <template #modal-footer>
      <gl-button v-if="canCancel" @click="closeModal">{{ $options.i18n.cancel }} </gl-button>

      <gl-button v-if="registered" variant="confirm" category="primary" @click="closeModal"
        >{{ $options.i18n.close }}
      </gl-button>

      <gl-button
        v-else
        :disabled="!nextButtonDisabled"
        variant="confirm"
        category="primary"
        @click="registerAgent"
        >{{ $options.i18n.registerAgentButton }}
      </gl-button>
    </template>
  </gl-modal>
</template>
