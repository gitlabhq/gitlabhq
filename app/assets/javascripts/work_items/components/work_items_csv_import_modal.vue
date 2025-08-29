<script>
import { GlModal, GlFormGroup } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { __, s__, sprintf } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import workItemsCsvImportMutation from '../graphql/work_items_csv_import.mutation.graphql';

export default {
  i18n: {
    maximumFileSizeText: __('The maximum file size allowed is %{size}.'),
    importWorkItemsText: s__('WorkItem|Import work items'),
    importIssuesText: __('Import issues'),
    uploadCsvFileText: __('Upload CSV file'),
    workItemMainText: s__(
      "WorkItem|Your work items will be imported in the background. Once finished, you'll get a confirmation email.",
    ),
    workItemHelpText: s__(
      'WorkItem|It must have a header row and at least two columns: the first column is the work item title and the second column is the work item description. The separator is automatically detected.',
    ),
    issuesMainText: __(
      "Your issues will be imported in the background. Once finished, you'll get a confirmation email.",
    ),
    issuesHelpText: __(
      'It must have a header row and at least two columns: the first column is the issue title and the second column is the issue description. The separator is automatically detected.',
    ),
  },
  actionCancel: {
    text: __('Cancel'),
  },
  components: {
    GlModal,
    GlFormGroup,
  },
  mixins: [glFeatureFlagMixin()],
  inject: {
    maxAttachmentSize: {
      default: 0,
    },
  },
  props: {
    modalId: {
      type: String,
      required: true,
    },
    fullPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isImporting: false,
      selectedFile: null,
    };
  },
  computed: {
    isPlanningViewsEnabled() {
      return this.glFeatures.workItemPlanningView;
    },
    maxFileSizeText() {
      return sprintf(this.$options.i18n.maximumFileSizeText, { size: this.maxAttachmentSize });
    },
    actionPrimary() {
      return {
        text: this.isPlanningViewsEnabled
          ? this.$options.i18n.importWorkItemsText
          : this.$options.i18n.importIssuesText,
        attributes: {
          variant: 'confirm',
          loading: this.isImporting,
          'data-testid': 'import-work-items-button',
          'data-track-action': 'click_button',
          'data-track-label': 'import_work_items_csv',
        },
      };
    },
    modalTitle() {
      return this.isPlanningViewsEnabled
        ? this.$options.i18n.importWorkItemsText
        : this.$options.i18n.importIssuesText;
    },
    descriptionText() {
      return this.isPlanningViewsEnabled
        ? this.$options.i18n.workItemMainText
        : this.$options.i18n.issuesMainText;
    },
    helpText() {
      return this.isPlanningViewsEnabled
        ? this.$options.i18n.workItemHelpText
        : this.$options.i18n.issuesHelpText;
    },
  },
  methods: {
    onFileChange(event) {
      const files = event.target?.files;
      this.selectedFile = files.length > 0 ? files[0] : null;
    },
    async importWorkItems() {
      if (!this.selectedFile) {
        createAlert({
          message: s__('WorkItem|Please select a file to import.'),
        });
        return;
      }

      this.isImporting = true;

      try {
        const { data } = await this.$apollo.mutate({
          mutation: workItemsCsvImportMutation,
          variables: {
            input: {
              projectPath: this.fullPath,
              file: this.selectedFile,
            },
          },
          context: {
            hasUpload: true,
          },
        });

        const { message } = data.workItemsCsvImport;

        if (message) {
          createAlert({
            message,
            variant: 'success',
          });
          this.$refs.modal?.hide();
          this.selectedFile = null;
          if (this.$refs.fileInput) {
            this.$refs.fileInput.value = '';
          }
        }
      } catch (error) {
        createAlert({
          message: this.isPlanningViewsEnabled
            ? s__('WorkItem|An error occurred while importing work items.')
            : s__('Issues|An error occurred while importing issues.'),
        });
      } finally {
        this.isImporting = false;
      }
    },
  },
};
</script>

<template>
  <gl-modal
    ref="modal"
    :modal-id="modalId"
    :title="modalTitle"
    :action-primary="actionPrimary"
    :action-cancel="$options.actionCancel"
    data-testid="import-work-items-modal"
    @primary="importWorkItems"
  >
    <p>
      {{ descriptionText }}
    </p>
    <gl-form-group :label="$options.i18n.uploadCsvFileText" class="gl-truncate" label-for="file">
      <input
        id="file"
        ref="fileInput"
        type="file"
        name="file"
        accept=".csv,text/csv"
        @change="onFileChange"
      />
    </gl-form-group>
    <p class="gl-text-subtle">
      {{ helpText }}
      {{ maxFileSizeText }}
    </p>
  </gl-modal>
</template>
