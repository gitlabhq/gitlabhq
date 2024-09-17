<script>
import { GlModal, GlButton, GlFormInput, GlSprintf } from '@gitlab/ui';
import csrf from '~/lib/utils/csrf';
import { s__ } from '~/locale';

export default {
  components: {
    GlModal,
    GlButton,
    GlFormInput,
    GlSprintf,
  },
  props: {
    clusterPath: {
      type: String,
      required: true,
    },
    clusterName: {
      type: String,
      required: true,
    },
    hasManagementProject: {
      type: Boolean,
      required: false,
    },
  },
  data() {
    return {
      enteredClusterName: '',
      confirmCleanup: false,
    };
  },
  computed: {
    csrfToken() {
      return csrf.token;
    },
    modalTitle() {
      return this.confirmCleanup
        ? s__('ClusterIntegration|Remove integration and resources?')
        : s__('ClusterIntegration|Remove integration?');
    },
    warningMessage() {
      return this.confirmCleanup
        ? s__(
            'ClusterIntegration|You are about to remove your cluster integration and all GitLab-created resources associated with this cluster.',
          )
        : s__('ClusterIntegration|You are about to remove your cluster integration.');
    },
    confirmationTextLabel() {
      return this.confirmCleanup
        ? s__(
            'ClusterIntegration|To remove your integration and resources, type %{clusterName} to confirm:',
          )
        : s__('ClusterIntegration|To remove your integration, type %{clusterName} to confirm:');
    },
    canSubmit() {
      return this.enteredClusterName === this.clusterName;
    },
    canCleanupResources() {
      return !this.hasManagementProject;
    },
    buttonCategory() {
      return !this.hasManagementProject ? 'secondary' : 'primary';
    },
  },
  methods: {
    handleClickRemoveCluster(cleanup = false) {
      this.confirmCleanup = cleanup;
      this.$refs.modal.show();
    },
    handleCancel() {
      this.$refs.modal.hide();
      this.enteredClusterName = '';
    },
    handleSubmit(cleanup = false) {
      this.$refs.cleanup.name = cleanup === true ? 'cleanup' : 'no_cleanup';
      this.$refs.form.submit();
      this.enteredClusterName = '';
    },
  },
};
</script>

<template>
  <div class="gl-flex">
    <gl-button
      v-if="canCleanupResources"
      data-testid="remove-integration-and-resources-button"
      class="gl-mr-3"
      variant="danger"
      @click="handleClickRemoveCluster(true)"
    >
      {{ s__('ClusterIntegration|Remove integration and resources') }}
    </gl-button>
    <gl-button
      data-testid="remove-integration-button"
      :category="buttonCategory"
      variant="danger"
      @click="handleClickRemoveCluster(false)"
    >
      {{ s__('ClusterIntegration|Remove integration') }}
    </gl-button>
    <gl-modal
      ref="modal"
      size="lg"
      modal-id="delete-cluster-modal"
      :title="modalTitle"
      kind="danger"
    >
      <p>{{ warningMessage }}</p>
      <div v-if="confirmCleanup">
        {{ s__('ClusterIntegration|This will permanently delete the following resources:') }}
        <ul>
          <li>{{ s__('ClusterIntegration|Any project namespaces') }}</li>
          <!-- eslint-disable @gitlab/vue-require-i18n-strings -->
          <li><code>clusterroles</code></li>
          <li><code>clusterrolebindings</code></li>
          <!-- eslint-enable @gitlab/vue-require-i18n-strings -->
        </ul>
      </div>
      <strong>
        <gl-sprintf :message="confirmationTextLabel">
          <template #clusterName>
            <code>{{ clusterName }}</code>
          </template>
        </gl-sprintf>
      </strong>
      <form ref="form" :action="clusterPath" method="post" class="gl-mb-5">
        <input ref="method" type="hidden" name="_method" value="delete" />
        <input :value="csrfToken" type="hidden" name="authenticity_token" />
        <input ref="cleanup" type="hidden" name="cleanup" value="true" />
        <gl-form-input
          v-model="enteredClusterName"
          autofocus
          type="text"
          name="confirm_cluster_name_input"
          autocomplete="off"
        />
      </form>
      <span v-if="confirmCleanup">{{
        s__(
          'ClusterIntegration|If you do not wish to delete all associated GitLab resources, you can simply remove the integration.',
        )
      }}</span>
      <template #modal-footer>
        <gl-button @click="handleCancel">{{ __('Cancel') }}</gl-button>
        <template v-if="confirmCleanup">
          <gl-button
            :disabled="!canSubmit"
            variant="danger"
            category="primary"
            @click="handleSubmit(true)"
            >{{ s__('ClusterIntegration|Remove integration and resources') }}</gl-button
          >
        </template>
        <template v-else>
          <gl-button
            :disabled="!canSubmit"
            data-testid="remove-integration-modal-button"
            variant="danger"
            category="primary"
            @click="handleSubmit"
            >{{ s__('ClusterIntegration|Remove integration') }}</gl-button
          >
        </template>
      </template>
    </gl-modal>
  </div>
</template>
