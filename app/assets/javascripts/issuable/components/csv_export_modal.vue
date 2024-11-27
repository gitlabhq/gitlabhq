<script>
import { GlModal, GlSprintf, GlIcon } from '@gitlab/ui';
import { TYPE_ISSUE } from '~/issues/constants';
import { __, n__ } from '~/locale';

export default {
  actionCancel: {
    text: __('Cancel'),
  },
  i18n: {
    exportText: __(
      'The CSV export will be created in the background. Once finished, it will be sent to %{email} in an attachment.',
    ),
  },
  components: {
    GlModal,
    GlSprintf,
    GlIcon,
  },
  inject: {
    issuableType: {
      default: TYPE_ISSUE,
    },
    email: {
      default: '',
    },
  },
  props: {
    exportCsvPath: {
      type: String,
      required: true,
    },
    issuableCount: {
      type: Number,
      required: true,
    },
    modalId: {
      type: String,
      required: true,
    },
  },
  computed: {
    actionPrimary() {
      return {
        text: this.exportText,
        attributes: {
          href: this.exportCsvPath,
          variant: 'confirm',
          'data-method': 'post',
          'data-testid': 'export-issues-button',
          'data-track-action': 'click_button',
          'data-track-label': this.dataTrackLabel,
        },
      };
    },
    isIssue() {
      return this.issuableType === TYPE_ISSUE;
    },
    dataTrackLabel() {
      return this.isIssue ? 'export_issues_csv' : 'export_merge-requests_csv';
    },
    exportText() {
      return this.isIssue ? __('Export issues') : __('Export merge requests');
    },
    issuableCountText() {
      return this.isIssue
        ? n__('1 issue selected', '%d issues selected', this.issuableCount)
        : n__('1 merge request selected', '%d merge requests selected', this.issuableCount);
    },
  },
};
</script>

<template>
  <gl-modal
    :modal-id="modalId"
    :action-primary="actionPrimary"
    :action-cancel="$options.actionCancel"
    body-class="!gl-p-0"
    :title="exportText"
    data-testid="export-issuable-modal"
  >
    <div
      class="gl-items-center gl-justify-start gl-border-1 gl-border-subtle gl-p-4 gl-border-b-solid"
    >
      <gl-icon name="check" class="gl-color-green-400" />
      <strong class="gl-m-3">{{ issuableCountText }}</strong>
    </div>
    <div class="modal-text gl-px-4 gl-py-5">
      <gl-sprintf :message="$options.i18n.exportText">
        <template #email>
          <strong>{{ email }}</strong>
        </template>
      </gl-sprintf>
    </div>
  </gl-modal>
</template>
