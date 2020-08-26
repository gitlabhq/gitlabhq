<script>
/* eslint-disable vue/no-v-html */
import { GlModal } from '@gitlab/ui';
import { sprintf, s__ } from '~/locale';
import { ELASTIC_STACK } from '../constants';

const CUSTOM_APP_WARNING_TEXT = {
  [ELASTIC_STACK]: s__(
    'ClusterIntegration|Your Elasticsearch cluster will be re-created during this upgrade. Your logs will be re-indexed, and you will lose historical logs from hosts terminated in the last 30 days.',
  ),
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
      return sprintf(s__('ClusterIntegration|Update %{appTitle}'), {
        appTitle: this.applicationTitle,
      });
    },
    warningText() {
      return sprintf(
        s__('ClusterIntegration|You are about to update %{appTitle} on your cluster.'),
        {
          appTitle: this.applicationTitle,
        },
      );
    },
    customAppWarningText() {
      return CUSTOM_APP_WARNING_TEXT[this.application];
    },
    modalId() {
      return `update-${this.application}`;
    },
  },
  methods: {
    confirmUpdate() {
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
    @ok="confirmUpdate()"
  >
    {{ warningText }} <span v-html="customAppWarningText"></span>
  </gl-modal>
</template>
