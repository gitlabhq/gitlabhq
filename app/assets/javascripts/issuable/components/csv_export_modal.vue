<script>
import { GlButton, GlModal, GlSprintf, GlIcon } from '@gitlab/ui';
import { ISSUABLE_TYPE } from '../constants';

export default {
  name: 'CsvExportModal',
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
  data() {
    return {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      issuableName: this.issuableType === ISSUABLE_TYPE.issues ? 'issues' : 'merge requests',
    };
  },
  issueableType: ISSUABLE_TYPE,
};
</script>

<template>
  <gl-modal :modal-id="modalId" body-class="gl-p-0!" data-qa-selector="export_issuable_modal">
    <template #modal-title>
      <gl-sprintf :message="__('Export %{name}')">
        <template #name>{{ issuableName }}</template>
      </gl-sprintf>
    </template>
    <div
      v-if="issuableCount > -1"
      class="gl-justify-content-start gl-align-items-center gl-p-4 gl-border-b-solid gl-border-1 gl-border-gray-50"
    >
      <gl-icon name="check" class="gl-color-green-400" />
      <strong class="gl-m-3">
        <gl-sprintf
          v-if="issuableType === $options.issueableType.issues"
          :message="n__('1 issue selected', '%d issues selected', issuableCount)"
        >
          <template #issuableCount>{{ issuableCount }}</template>
        </gl-sprintf>
        <gl-sprintf
          v-else
          :message="n__('1 merge request selected', '%d merge request selected', issuableCount)"
        >
          <template #issuableCount>{{ issuableCount }}</template>
        </gl-sprintf>
      </strong>
    </div>
    <div class="modal-text gl-px-4 gl-py-5">
      <gl-sprintf
        :message="
          __(
            `The CSV export will be created in the background. Once finished, it will be sent to %{strongStart}${email}%{strongEnd} in an attachment.`,
          )
        "
      >
        <template #strong="{ content }">
          <strong>{{ content }}</strong>
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
        data-track-event="click_button"
        :data-track-label="`export_${issuableType}_csv`"
      >
        <gl-sprintf :message="__('Export %{name}')">
          <template #name>{{ issuableName }}</template>
        </gl-sprintf>
      </gl-button>
    </template>
  </gl-modal>
</template>
