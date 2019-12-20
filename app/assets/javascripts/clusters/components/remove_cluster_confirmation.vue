<script>
import _ from 'underscore';
import SplitButton from '~/vue_shared/components/split_button.vue';
import { GlModal, GlButton, GlFormInput } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import csrf from '~/lib/utils/csrf';

const splitButtonActionItems = [
  {
    title: s__('ClusterIntegration|Remove integration and resources'),
    description: s__(
      'ClusterIntegration|Deletes all GitLab resources attached to this cluster during removal',
    ),
    eventName: 'remove-cluster-and-cleanup',
  },
  {
    title: s__('ClusterIntegration|Remove integration'),
    description: s__(
      'ClusterIntegration|Removes cluster from project but keeps associated resources',
    ),
    eventName: 'remove-cluster',
  },
];

export default {
  splitButtonActionItems,
  components: {
    SplitButton,
    GlModal,
    GlButton,
    GlFormInput,
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
    warningToBeRemoved() {
      return s__(`ClusterIntegration|
        This will permanently delete the following resources:
        <ul>
          <li>All installed applications and related resources</li>
          <li>The <code>gitlab-managed-apps</code> namespace</li>
          <li>Any project namespaces</li>
          <li><code>clusterroles</code></li>
          <li><code>clusterrolebindings</code></li>
        </ul>
      `);
    },
    confirmationTextLabel() {
      return sprintf(
        this.confirmCleanup
          ? s__(
              'ClusterIntegration|To remove your integration and resources, type %{clusterName} to confirm:',
            )
          : s__('ClusterIntegration|To remove your integration, type %{clusterName} to confirm:'),
        {
          clusterName: `<code>${_.escape(this.clusterName)}</code>`,
        },
        false,
      );
    },
    canSubmit() {
      return this.enteredClusterName === this.clusterName;
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
  <div>
    <split-button
      :action-items="$options.splitButtonActionItems"
      menu-class="dropdown-menu-large"
      variant="danger"
      @remove-cluster="handleClickRemoveCluster(false)"
      @remove-cluster-and-cleanup="handleClickRemoveCluster(true)"
    />
    <gl-modal
      ref="modal"
      size="lg"
      modal-id="delete-cluster-modal"
      :title="modalTitle"
      kind="danger"
    >
      <template>
        <p>{{ warningMessage }}</p>
        <div v-if="confirmCleanup" v-html="warningToBeRemoved"></div>
        <strong v-html="confirmationTextLabel"></strong>
        <form ref="form" :action="clusterPath" method="post" class="append-bottom-20">
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
      </template>
      <template slot="modal-footer">
        <gl-button variant="secondary" @click="handleCancel">{{ s__('Cancel') }}</gl-button>
        <template v-if="confirmCleanup">
          <gl-button :disabled="!canSubmit" variant="warning" @click="handleSubmit">{{
            s__('ClusterIntegration|Remove integration')
          }}</gl-button>
          <gl-button :disabled="!canSubmit" variant="danger" @click="handleSubmit(true)">{{
            s__('ClusterIntegration|Remove integration and resources')
          }}</gl-button>
        </template>
        <template v-else>
          <gl-button :disabled="!canSubmit" variant="danger" @click="handleSubmit">{{
            s__('ClusterIntegration|Remove integration')
          }}</gl-button>
        </template>
      </template>
    </gl-modal>
  </div>
</template>
