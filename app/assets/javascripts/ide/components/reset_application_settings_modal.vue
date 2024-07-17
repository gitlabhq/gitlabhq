<script>
import { GlAlert, GlModal } from '@gitlab/ui';
import { s__ } from '~/locale';
import axios from '~/lib/utils/axios_utils';

export const I18N_RESET_APPLICATION_SETTINGS_MODAL = {
  errorMessage: s__(
    'IDE|An error occurred while restoring the application to default. Please try again.',
  ),
  title: s__('IDE|Restore application to default'),
  body: s__(
    'IDE|Are you sure you want to restore this application to its original configuration? All your changes will be lost.',
  ),
  primaryButton: s__('IDE|Confirm'),
  cancel: s__('IDE|Cancel'),
};

export default {
  name: 'ResetApplicationSettingsModal',
  components: {
    GlAlert,
    GlModal,
  },
  props: {
    visible: {
      type: Boolean,
      required: true,
    },
    resetApplicationSettingsPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      loading: false,
      showErrorAlert: false,
    };
  },
  computed: {
    modalActionPrimary() {
      return {
        text: I18N_RESET_APPLICATION_SETTINGS_MODAL.primaryButton,
        attributes: {
          variant: 'danger',
          id: 'confirm-restore-button',
          loading: this.loading,
          type: 'submit',
        },
      };
    },
    modalActionSecondary() {
      return {
        text: I18N_RESET_APPLICATION_SETTINGS_MODAL.cancel,
        attributes: {
          loading: this.loading,
        },
      };
    },
  },
  methods: {
    handlePrimaryButtonClick(event) {
      event.preventDefault();
      this.resetApplicationSetings();
    },
    async resetApplicationSetings() {
      this.loading = true;
      this.showErrorAlert = false;
      try {
        await axios.post(this.resetApplicationSettingsPath);
        this.$refs.modal.hide();
        window.location.reload();
      } catch (e) {
        this.showErrorAlert = true;
      }

      this.loading = false;
    },
  },
  i18n: I18N_RESET_APPLICATION_SETTINGS_MODAL,
};
</script>
<template>
  <gl-modal
    ref="modal"
    size="sm"
    modal-id="reset-application-settings-modal"
    :visible="visible"
    :title="$options.i18n.title"
    :action-primary="modalActionPrimary"
    :action-secondary="modalActionSecondary"
    v-bind="$attrs"
    v-on="$listeners"
    @primary="handlePrimaryButtonClick"
  >
    <div>
      <gl-alert v-if="showErrorAlert" variant="danger" class="gl-mb-5" :dismissible="false">
        {{ $options.i18n.errorMessage }}
      </gl-alert>
      <p>{{ $options.i18n.body }}</p>
    </div>
  </gl-modal>
</template>
