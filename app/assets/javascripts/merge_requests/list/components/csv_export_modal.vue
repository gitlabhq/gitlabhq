<script>
import { GlModal, GlSprintf, GlIcon } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { TYPE_ISSUE } from '~/issues/constants';
import { __, n__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  name: 'CsvExportModal',
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
  mixins: [glFeatureFlagsMixin()],
  inject: {
    issuableType: {
      default: TYPE_ISSUE,
    },
    email: {
      default: '',
    },
    exportMergeRequestsCsvMutation: {
      default: null,
    },
  },
  props: {
    exportCsvPath: {
      type: String,
      required: true,
    },
    exportVariables: {
      type: Object,
      required: false,
      default: () => ({}),
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
      isExporting: false,
    };
  },
  computed: {
    exportsThroughGraphql() {
      return Boolean(
        this.exportMergeRequestsCsvMutation && this.glFeatures.mergeRequestsCsvExportGraphql,
      );
    },
    actionPrimary() {
      const attributes = {
        variant: 'confirm',
        'data-testid': 'export-issues-button',
        'data-track-action': 'click_button',
        'data-track-label': this.dataTrackLabel,
      };

      if (this.exportsThroughGraphql) {
        return { text: this.exportText, attributes: { ...attributes, loading: this.isExporting } };
      }

      return {
        text: this.exportText,
        attributes: { ...attributes, href: this.exportCsvPath, 'data-method': 'post' },
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
  methods: {
    async exportMergeRequests() {
      if (!this.exportsThroughGraphql) return;

      this.isExporting = true;

      try {
        const { data } = await this.$apollo.mutate({
          mutation: this.exportMergeRequestsCsvMutation,
          variables: this.exportVariables,
        });
        const { message, errors } = data.mergeRequestsCsvExport;

        if (errors.length) throw new Error(errors.join(', '));

        createAlert({ message, variant: 'success' });
      } catch {
        createAlert({ message: __('An error occurred while exporting merge requests.') });
      } finally {
        this.isExporting = false;
      }
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
    @primary="exportMergeRequests"
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
