<script>
import { GlButton, GlDropdown, GlModal } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { __, sprintf } from '~/locale';
import { createAlert, VARIANT_SUCCESS } from '~/alert';
import { ACTIONS_I18N } from '../constants';

const modalActionButtonAttributes = {
  block: {
    text: __('OK'),
    attributes: {
      variant: 'confirm',
    },
  },
  removeUserAndReport: {
    text: __('OK'),
    attributes: {
      variant: 'danger',
    },
  },
  secondary: {
    text: __('Cancel'),
    attributes: {
      variant: 'default',
    },
  },
};

export default {
  name: 'AbuseReportActions',
  components: {
    GlButton,
    GlDropdown,
    GlModal,
  },
  modalId: 'abuse-report-row-action-confirm-modal',
  modalActionButtonAttributes,
  i18n: ACTIONS_I18N,
  props: {
    report: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      userBlocked: this.report.userBlocked,
      confirmModalShown: false,
      actionToConfirm: 'block',
    };
  },
  computed: {
    blockUserButtonText() {
      const { alreadyBlocked, blockUser } = this.$options.i18n;

      return this.userBlocked ? alreadyBlocked : blockUser;
    },
    removeUserAndReportConfirmText() {
      return sprintf(this.$options.i18n.removeUserAndReportConfirm, {
        user: this.report.reportedUser.name,
      });
    },
    modalData() {
      return {
        block: {
          action: this.blockUser,
          confirmText: this.$options.i18n.blockUserConfirm,
        },
        removeUserAndReport: {
          action: this.removeUserAndReport,
          confirmText: this.removeUserAndReportConfirmText,
        },
      };
    },
  },
  methods: {
    showConfirmModal(action) {
      this.confirmModalShown = true;
      this.actionToConfirm = action;
    },
    blockUser() {
      axios
        .put(this.report.blockUserPath)
        .then(this.handleBlockUserResponse)
        .catch(this.handleError);
    },
    removeUserAndReport() {
      axios
        .delete(this.report.removeUserAndReportPath)
        .then(this.handleRemoveReportResponse)
        .catch(this.handleError);
    },
    removeReport() {
      axios
        .delete(this.report.removeReportPath)
        .then(this.handleRemoveReportResponse)
        .catch(this.handleError);
    },
    handleRemoveReportResponse() {
      window.location.reload();
    },
    handleBlockUserResponse({ data }) {
      const message = data?.error || data?.notice;
      const alertOptions = data?.notice ? { variant: VARIANT_SUCCESS } : {};

      if (message) {
        createAlert({ message, ...alertOptions });
      }

      if (!data?.error) {
        this.userBlocked = true;
      }
    },
    handleError(error) {
      createAlert({
        message: __('Something went wrong. Please try again.'),
        captureError: true,
        error,
      });
    },
  },
};
</script>

<template>
  <gl-dropdown text="Actions" text-sr-only icon="ellipsis_v" category="tertiary" no-caret right>
    <div class="gl-px-2">
      <gl-button block variant="danger" @click="showConfirmModal('removeUserAndReport')">
        {{ $options.i18n.removeUserAndReport }}
      </gl-button>
      <gl-button block :disabled="userBlocked" @click="showConfirmModal('block')">
        {{ blockUserButtonText }}
      </gl-button>
      <gl-button block @click="removeReport">
        {{ $options.i18n.removeReport }}
      </gl-button>
    </div>
    <gl-modal
      v-model="confirmModalShown"
      :modal-id="$options.modalId"
      :title="modalData[actionToConfirm].confirmText"
      size="sm"
      :action-primary="$options.modalActionButtonAttributes[actionToConfirm]"
      :action-secondary="$options.modalActionButtonAttributes.secondary"
      @primary="modalData[actionToConfirm].action"
    />
  </gl-dropdown>
</template>
