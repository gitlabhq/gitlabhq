<script>
import { GlButton, GlModal, GlSprintf, GlIcon } from '@gitlab/ui';
import { __, n__ } from '~/locale';
import { ISSUABLE_TYPE } from '../constants';

export default {
  i18n: {
    exportText: __(
      'The CSV export will be created in the background. Once finished, it will be sent to %{email} in an attachment.',
    ),
  },
  components: {
    GlButton,
    GlModal,
    GlSprintf,
    GlIcon,
  },
  inject: {
    issuableType: {
      default: ISSUABLE_TYPE.issues,
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
    isIssue() {
      return this.issuableType === ISSUABLE_TYPE.issues;
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
    body-class="gl-p-0!"
    :title="exportText"
    data-qa-selector="export_issuable_modal"
  >
    <div
      class="gl-justify-content-start gl-align-items-center gl-p-4 gl-border-b-solid gl-border-1 gl-border-gray-50"
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
    <template #modal-footer>
      <gl-button
        category="primary"
        variant="confirm"
        :href="exportCsvPath"
        data-method="post"
        :data-qa-selector="`export_${issuableType}_button`"
        data-track-action="click_button"
        :data-track-label="`export_${issuableType}_csv`"
      >
        {{ exportText }}
      </gl-button>
    </template>
  </gl-modal>
</template>
