<script>
import {
  GlButton,
  GlModal,
  GlModalDirective,
  GlSprintf,
  GlFormGroup,
  GlFormInput,
  GlTooltipDirective,
} from '@gitlab/ui';
import { sprintf } from '~/locale';
import { DELETE_AGENT_BUTTON, DELETE_AGENT_MODAL_ID } from '../constants';
import deleteAgent from '../graphql/mutations/delete_agent.mutation.graphql';
import getAgentsQuery from '../graphql/queries/get_agents.query.graphql';
import { removeAgentFromStore } from '../graphql/cache_update';

export default {
  i18n: DELETE_AGENT_BUTTON,
  components: {
    GlButton,
    GlModal,
    GlSprintf,
    GlFormGroup,
    GlFormInput,
  },
  directives: {
    GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  inject: ['projectPath', 'canAdminCluster'],
  props: {
    agent: {
      required: true,
      type: Object,
      validator: (value) => ['id', 'name'].every((prop) => value[prop]),
    },
    defaultBranchName: {
      default: '.noBranch',
      required: false,
      type: String,
    },
  },
  data() {
    return {
      loading: false,
      error: null,
      deleteConfirmText: null,
      agentName: this.agent.name,
    };
  },
  computed: {
    deleteButtonDisabled() {
      return this.loading || !this.canAdminCluster;
    },
    deleteButtonTooltip() {
      const { deleteButton, disabledHint } = this.$options.i18n;
      return this.deleteButtonDisabled ? disabledHint : deleteButton;
    },
    getAgentsQueryVariables() {
      return {
        defaultBranchName: this.defaultBranchName,
        projectPath: this.projectPath,
      };
    },
    modalId() {
      return sprintf(DELETE_AGENT_MODAL_ID, {
        agentName: this.agent.name,
      });
    },
    primaryModalProps() {
      return {
        text: this.$options.i18n.modalAction,
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
      return this.deleteConfirmText !== this.agent.name;
    },
    containerTabIndex() {
      return this.canAdminCluster ? -1 : 0;
    },
  },
  methods: {
    async deleteAgent() {
      if (this.disableModalSubmit || this.loading) {
        return;
      }

      this.loading = true;
      this.error = null;

      try {
        const { errors } = await this.deleteAgentMutation();

        if (errors.length) {
          throw new Error(errors[0]);
        }
      } catch (error) {
        this.error = error?.message || this.$options.i18n.defaultError;
      } finally {
        this.loading = false;
        const successMessage = sprintf(this.$options.i18n.successMessage, { name: this.agentName });

        this.$toast.show(this.error || successMessage);

        this.$refs.modal?.hide();
      }
    },
    deleteAgentMutation() {
      return this.$apollo
        .mutate({
          mutation: deleteAgent,
          variables: {
            input: {
              id: this.agent.id,
            },
          },
          update: (store) => {
            const deleteClusterAgent = this.agent;
            removeAgentFromStore(
              store,
              deleteClusterAgent,
              getAgentsQuery,
              this.getAgentsQueryVariables,
            );
          },
        })

        .then(({ data: { clusterAgentDelete } }) => {
          return clusterAgentDelete;
        });
    },
    hideModal() {
      this.loading = false;
      this.error = null;
      this.deleteConfirmText = null;
    },
  },
};
</script>

<template>
  <div>
    <div
      v-gl-tooltip="deleteButtonTooltip"
      :tabindex="containerTabIndex"
      class="cluster-button-container gl-rounded-base gl-display-inline-block"
      data-testid="delete-agent-button-tooltip"
    >
      <gl-button
        ref="deleteAgentButton"
        v-gl-modal-directive="modalId"
        icon="remove"
        category="secondary"
        variant="danger"
        :disabled="deleteButtonDisabled"
        :aria-label="$options.i18n.deleteButton"
      />
    </div>

    <gl-modal
      ref="modal"
      :modal-id="modalId"
      :title="$options.i18n.modalTitle"
      :action-primary="primaryModalProps"
      :action-cancel="cancelModalProps"
      size="sm"
      @primary="deleteAgent"
      @hide="hideModal"
    >
      <p>{{ $options.i18n.modalBody }}</p>

      <gl-form-group>
        <template #label>
          <gl-sprintf :message="$options.i18n.modalInputLabel">
            <template #name>
              <code>{{ agent.name }}</code>
            </template>
          </gl-sprintf>
        </template>
        <gl-form-input v-model="deleteConfirmText" @keydown.enter="deleteAgent" />
      </gl-form-group>
    </gl-modal>
  </div>
</template>
