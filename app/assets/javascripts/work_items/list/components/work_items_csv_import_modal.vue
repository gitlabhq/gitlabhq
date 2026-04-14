<script>
import { GlModal, GlFormGroup } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { __, s__, sprintf } from '~/locale';
import workItemsCsvImportMutation from '../graphql/work_items_csv_import.mutation.graphql';

export default {
  name: 'WorkItemsCsvImportModal',
  i18n: {
    maximumFileSizeText: __('The maximum file size allowed is %{size}.'),
    importWorkItemsText: s__('WorkItem|Import work items'),
    uploadCsvFileText: __('Upload CSV file'),
    workItemMainText: s__(
      "WorkItem|Your work items will be imported in the background. Once finished, you'll get a confirmation email.",
    ),
    workItemHelpText: s__(
      'WorkItem|It must have a header row and at least two columns: the first column is the work item title and the second column is the work item description. The separator is automatically detected.',
    ),
  },
  actionCancel: {
    text: __('Cancel'),
  },
  components: {
    GlModal,
    GlFormGroup,
  },
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
    maxFileSizeText() {
      return sprintf(this.$options.i18n.maximumFileSizeText, { size: this.maxAttachmentSize });
    },
    actionPrimary() {
      return {
        text: this.$options.i18n.importWorkItemsText,
        attributes: {
          variant: 'confirm',
          loading: this.isImporting,
          'data-testid': 'import-work-items-button',
          'data-track-action': 'click_button',
          'data-track-label': 'import_work_items_csv',
        },
      };
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
          message: s__('WorkItem|An error occurred while importing work items.'),
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
    :title="$options.i18n.importWorkItemsText"
    :action-primary="actionPrimary"
    :action-cancel="$options.actionCancel"
    data-testid="import-work-items-modal"
    @primary="importWorkItems"
  >
    <p>
      {{ $options.i18n.workItemMainText }}
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
      {{ $options.i18n.workItemHelpText }}
      {{ maxFileSizeText }}
    </p>
  </gl-modal>
</template>
