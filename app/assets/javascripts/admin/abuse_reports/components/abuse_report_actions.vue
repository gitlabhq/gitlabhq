<script>
import { GlDisclosureDropdown, GlModal } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { __, sprintf } from '~/locale';
import { redirectTo, refreshCurrentPage } from '~/lib/utils/url_utility'; // eslint-disable-line import/no-deprecated
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
const BLOCK_ACTION = 'block';
const REMOVE_USER_AND_REPORT_ACTION = 'removeUserAndReport';

export default {
  name: 'AbuseReportActions',
  components: {
    GlDisclosureDropdown,
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
        [BLOCK_ACTION]: {
          action: this.blockUser,
          confirmText: this.$options.i18n.blockUserConfirm,
        },
        [REMOVE_USER_AND_REPORT_ACTION]: {
          action: this.removeUserAndReport,
          confirmText: this.removeUserAndReportConfirmText,
        },
      };
    },
    reportActionsDropdownItems() {
      return [
        {
          text: this.$options.i18n.removeUserAndReport,
          action: () => {
            this.showConfirmModal(REMOVE_USER_AND_REPORT_ACTION);
          },
          extraAttrs: { class: 'gl-text-red-500!' },
        },
        {
          text: this.blockUserButtonText,
          action: () => {
            this.showConfirmModal(BLOCK_ACTION);
          },
          extraAttrs: {
            disabled: this.userBlocked,
            'data-testid': 'block-user-button',
          },
        },
        {
          text: this.$options.i18n.removeReport,
          action: () => {
            this.removeReport();
          },
        },
      ];
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
      // eslint-disable-next-line import/no-deprecated
      if (this.report.redirectPath) redirectTo(this.report.redirectPath);
      else refreshCurrentPage();
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
  <div>
    <gl-disclosure-dropdown
      :toggle-text="$options.i18n.actionsToggleText"
      text-sr-only
      icon="ellipsis_v"
      category="tertiary"
      no-caret
      placement="right"
      :items="reportActionsDropdownItems"
    />
    <gl-modal
      v-model="confirmModalShown"
      :modal-id="$options.modalId"
      :title="modalData[actionToConfirm].confirmText"
      size="sm"
      :action-primary="$options.modalActionButtonAttributes[actionToConfirm]"
      :action-secondary="$options.modalActionButtonAttributes.secondary"
      @primary="modalData[actionToConfirm].action"
    />
  </div>
</template>
