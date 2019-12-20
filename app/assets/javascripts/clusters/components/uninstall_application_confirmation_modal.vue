<script>
import { GlModal } from '@gitlab/ui';
import trackUninstallButtonClickMixin from 'ee_else_ce/clusters/mixins/track_uninstall_button_click';
import { sprintf, s__ } from '~/locale';
import {
  HELM,
  INGRESS,
  CERT_MANAGER,
  PROMETHEUS,
  RUNNER,
  KNATIVE,
  JUPYTER,
  ELASTIC_STACK,
} from '../constants';

const CUSTOM_APP_WARNING_TEXT = {
  [HELM]: sprintf(
    s__(
      'ClusterIntegration|The associated Tiller pod, the %{gitlabManagedAppsNamespace} namespace, and all of its resources will be deleted and cannot be restored.',
    ),
    {
      gitlabManagedAppsNamespace: '<code>gitlab-managed-apps</code>',
    },
    false,
  ),
  [INGRESS]: s__(
    'ClusterIntegration|The associated load balancer and IP will be deleted and cannot be restored.',
  ),
  [CERT_MANAGER]: s__(
    'ClusterIntegration|The associated private key will be deleted and cannot be restored.',
  ),
  [PROMETHEUS]: s__('ClusterIntegration|All data will be deleted and cannot be restored.'),
  [RUNNER]: s__('ClusterIntegration|Any running pipelines will be canceled.'),
  [KNATIVE]: s__(
    'ClusterIntegration|The associated IP and all deployed services will be deleted and cannot be restored. Uninstalling Knative will also remove Istio from your cluster. This will not effect any other applications.',
  ),
  [JUPYTER]: s__(
    'ClusterIntegration|All data not committed to GitLab will be deleted and cannot be restored.',
  ),
  [ELASTIC_STACK]: s__('ClusterIntegration|All data will be deleted and cannot be restored.'),
};

export default {
  components: {
    GlModal,
  },
  mixins: [trackUninstallButtonClickMixin],
  props: {
    application: {
      type: String,
      required: true,
    },
    applicationTitle: {
      type: String,
      required: true,
    },
  },
  computed: {
    title() {
      return sprintf(s__('ClusterIntegration|Uninstall %{appTitle}'), {
        appTitle: this.applicationTitle,
      });
    },
    warningText() {
      return sprintf(
        s__('ClusterIntegration|You are about to uninstall %{appTitle} from your cluster.'),
        {
          appTitle: this.applicationTitle,
        },
      );
    },
    customAppWarningText() {
      return CUSTOM_APP_WARNING_TEXT[this.application];
    },
    modalId() {
      return `uninstall-${this.application}`;
    },
  },
  methods: {
    confirmUninstall() {
      this.trackUninstallButtonClick(this.application);
      this.$emit('confirm');
    },
  },
};
</script>
<template>
  <gl-modal
    ok-variant="danger"
    cancel-variant="light"
    :ok-title="title"
    :modal-id="modalId"
    :title="title"
    @ok="confirmUninstall()"
  >
    {{ warningText }} <span v-html="customAppWarningText"></span>
  </gl-modal>
</template>
