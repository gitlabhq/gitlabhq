<script>
import {
  GlDropdown,
  GlDropdownItem,
  GlModal,
  GlModalDirective,
  GlSprintf,
  GlFormGroup,
  GlFormInput,
} from '@gitlab/ui';
import { s__, __, sprintf } from '~/locale';
import { DELETE_AGENT_MODAL_ID } from '../constants';
import deleteAgent from '../graphql/mutations/delete_agent.mutation.graphql';
import getAgentsQuery from '../graphql/queries/get_agents.query.graphql';
import { removeAgentFromStore } from '../graphql/cache_update';

export default {
  i18n: {
    dropdownText: __('More options'),
    deleteButton: s__('ClusterAgents|Delete agent'),
    modalTitle: __('Are you sure?'),
    modalBody: s__(
      'ClusterAgents|Are you sure you want to delete this agent? You cannot undo this.',
    ),
    modalInputLabel: s__('ClusterAgents|To delete the agent, type %{name} to confirm:'),
    modalAction: s__('ClusterAgents|Delete'),
    modalCancel: __('Cancel'),
    successMessage: s__('ClusterAgents|%{name} successfully deleted'),
    defaultError: __('An error occurred. Please try again.'),
  },
  components: {
    GlDropdown,
    GlDropdownItem,
    GlModal,
    GlSprintf,
    GlFormGroup,
    GlFormInput,
  },
  directives: {
    GlModalDirective,
  },
  inject: ['projectPath'],
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
    maxAgents: {
      default: null,
      required: false,
      type: Number,
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
    getAgentsQueryVariables() {
      return {
        defaultBranchName: this.defaultBranchName,
        first: this.maxAgents,
        last: null,
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
        attributes: [
          { disabled: this.loading || this.disableModalSubmit, loading: this.loading },
          { variant: 'danger' },
        ],
      };
    },
    cancelModalProps() {
      return {
        text: this.$options.i18n.modalCancel,
        attributes: [],
      };
    },
    disableModalSubmit() {
      return this.deleteConfirmText !== this.agent.name;
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

        this.$refs.modal.hide();
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
    <gl-dropdown
      icon="ellipsis_v"
      right
      :disabled="loading"
      :text="$options.i18n.dropdownText"
      text-sr-only
      category="tertiary"
      no-caret
    >
      <gl-dropdown-item v-gl-modal-directive="modalId">
        {{ $options.i18n.deleteButton }}
      </gl-dropdown-item>
    </gl-dropdown>

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
