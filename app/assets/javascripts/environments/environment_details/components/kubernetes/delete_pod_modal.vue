<script>
import { GlModal, GlSprintf, GlButton } from '@gitlab/ui';
import { isEmpty } from 'lodash';
import { s__, __ } from '~/locale';
import { createAlert } from '~/alert';
import deleteKubernetesPodMutation from '../../../graphql/mutations/delete_kubernetes_pod.mutation.graphql';

export default {
  components: {
    GlModal,
    GlSprintf,
    GlButton,
  },
  props: {
    pod: {
      type: Object,
      required: false,
      default: () => {},
    },
    configuration: {
      required: true,
      type: Object,
    },
    agentId: {
      required: true,
      type: String,
    },
    environmentId: {
      required: true,
      type: String,
    },
  },
  data() {
    return {
      visible: false,
      isLoading: false,
    };
  },
  watch: {
    pod(newValue) {
      this.visible = !isEmpty(newValue);
    },
  },
  methods: {
    hideModal() {
      this.visible = false;
      this.$emit('close');
    },
    deletePod() {
      this.isLoading = true;
      this.$apollo
        .mutate({
          mutation: deleteKubernetesPodMutation,
          variables: {
            configuration: this.configuration,
            namespace: this.pod.namespace,
            podName: this.pod.name,
          },
        })
        .then(({ data }) => {
          const { errors } = data.deleteKubernetesPod;

          if (errors?.length) {
            createAlert({
              message: this.$options.i18n.error + errors[0],
              variant: 'danger',
            });
          } else {
            this.$toast.show(this.$options.i18n.success);
            this.$emit('pod-deleted');
          }
        })
        .catch((error) => {
          createAlert({ message: this.$options.i18n.error + error.message, variant: 'danger' });
        })
        .finally(() => {
          this.isLoading = false;
          this.hideModal();
        });
    },
  },
  i18n: {
    title: s__('Environments|Delete %{podName}?'),
    description: s__(
      'Environments|Are you sure you want to delete %{podName}? This action cannot be undone.',
    ),
    buttonPrimary: s__('Environments|Delete pod'),
    buttonCancel: __('Cancel'),
    success: s__('Environments|Pod deleted successfully'),
    error: __('Error: '),
  },
  DELETE_POD_MODAL_ID: 'delete-pod-modal',
};
</script>
<template>
  <gl-modal
    v-model="visible"
    :modal-id="$options.DELETE_POD_MODAL_ID"
    :aria-label="$options.i18n.buttonPrimary"
    @hide="hideModal"
  >
    <template #modal-title>
      <gl-sprintf :message="$options.i18n.title">
        <template #podName>
          <strong>{{ pod.name }}</strong>
        </template>
      </gl-sprintf>
    </template>

    <gl-sprintf :message="$options.i18n.description">
      <template #podName>
        <strong>{{ pod.name }}</strong>
      </template>
    </gl-sprintf>

    <template #modal-footer>
      <gl-button @click="hideModal">{{ $options.i18n.buttonCancel }} </gl-button>

      <gl-button
        :loading="isLoading"
        variant="danger"
        category="primary"
        data-testid="delete-pod-button"
        data-event-tracking="click_delete_pod"
        :data-event-label="agentId"
        :data-event-property="environmentId"
        @click="deletePod"
        >{{ $options.i18n.buttonPrimary }}
      </gl-button>
    </template>
  </gl-modal>
</template>
