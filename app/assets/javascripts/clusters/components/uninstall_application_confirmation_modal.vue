<script>
import { GlModal } from '@gitlab/ui';
import { sprintf, s__ } from '~/locale';
import { INGRESS, CERT_MANAGER, PROMETHEUS, RUNNER, KNATIVE, JUPYTER } from '../constants';

const CUSTOM_APP_WARNING_TEXT = {
  [INGRESS]: s__(
    'ClusterIntegration|The associated load balancer and IP will be deleted and cannot be restored.',
  ),
  [CERT_MANAGER]: s__(
    'ClusterIntegration|The associated certifcate will be deleted and cannot be restored.',
  ),
  [PROMETHEUS]: s__('ClusterIntegration|All data will be deleted and cannot be restored.'),
  [RUNNER]: s__('ClusterIntegration|Any running pipelines will be canceled.'),
  [KNATIVE]: s__('ClusterIntegration|The associated IP will be deleted and cannot be restored.'),
  [JUPYTER]: '',
};

export default {
  components: {
    GlModal,
  },
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
};
</script>
<template>
  <gl-modal
    ok-variant="danger"
    cancel-variant="light"
    :ok-title="title"
    :modal-id="modalId"
    :title="title"
    @ok="$emit('confirm')"
    >{{ warningText }} {{ customAppWarningText }}</gl-modal
  >
</template>
