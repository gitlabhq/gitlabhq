<script>
import { GlModal, GlSprintf, GlIcon } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { __, n__, s__ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import workItemsCsvExportMutation from '../graphql/work_items_csv_export.mutation.graphql';

export default {
  actionCancel: {
    text: __('Cancel'),
  },
  i18n: {
    workItemExportTitle: s__('WorkItem|Export work items'),
    workItemErrorMessage: s__('WorkItem|An error occurred while exporting work items.'),
    issueExportTitle: s__('WorkItem|Export issues'),
    issueErrorMessage: s__('WorkItem|An error occurred while exporting issues.'),
    exportText: s__(
      'WorkItem|The CSV export will be created in the background. Once finished, it will be sent to %{email} in an attachment.',
    ),
  },
  components: {
    GlModal,
    GlSprintf,
    GlIcon,
  },
  mixins: [glFeatureFlagMixin()],
  inject: {
    userExportEmail: {
      default: '',
    },
  },
  props: {
    workItemCount: {
      type: Number,
      required: true,
    },
    modalId: {
      type: String,
      required: true,
    },
    queryVariables: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      isExporting: false,
    };
  },
  computed: {
    isPlanningViewsEnabled() {
      return this.glFeatures.workItemPlanningView;
    },
    actionPrimary() {
      return {
        text: this.isPlanningViewsEnabled
          ? this.$options.i18n.workItemExportTitle
          : this.$options.i18n.issueExportTitle,
        attributes: {
          variant: 'confirm',
          loading: this.isExporting,
          'data-testid': 'export-work-items-button',
          'data-track-action': 'click_button',
          'data-track-label': 'export_work_items_csv',
        },
      };
    },
    workItemCountText() {
      return this.isPlanningViewsEnabled
        ? n__('1 work item selected', '%d work items selected', this.workItemCount)
        : n__('1 issue selected', '%d issues selected', this.workItemCount);
    },
    modalTitle() {
      return this.isPlanningViewsEnabled
        ? this.$options.i18n.workItemExportTitle
        : this.$options.i18n.issueExportTitle;
    },
    exportErrorMessage() {
      return this.isPlanningViewsEnabled
        ? this.$options.i18n.workItemErrorMessage
        : this.$options.i18n.issueErrorMessage;
    },
  },
  methods: {
    async exportWorkItems() {
      this.isExporting = true;

      try {
        const { data } = await this.$apollo.mutate({
          mutation: workItemsCsvExportMutation,
          variables: {
            input: {
              ...this.queryVariables,
            },
          },
        });

        const { message } = data.workItemsCsvExport || {};

        if (message) {
          createAlert({
            message,
            variant: 'success',
          });
          this.$refs.modal?.hide();
        }
      } catch (error) {
        createAlert({
          message: this.exportErrorMessage,
        });
      } finally {
        this.isExporting = false;
      }
    },
  },
};
</script>

<template>
  <gl-modal
    ref="modal"
    :modal-id="modalId"
    :action-primary="actionPrimary"
    :action-cancel="$options.actionCancel"
    body-class="!gl-p-0"
    :title="modalTitle"
    data-testid="export-work-items-modal"
    @primary="exportWorkItems"
  >
    <div
      class="gl-items-center gl-justify-start gl-border-1 gl-border-subtle gl-p-4 gl-border-b-solid"
    >
      <gl-icon name="check" class="gl-color-green-400" />
      <strong class="gl-m-3">{{ workItemCountText }}</strong>
    </div>
    <div class="modal-text gl-px-4 gl-py-5">
      <gl-sprintf :message="$options.i18n.exportText">
        <template #email>
          <strong>{{ userExportEmail }}</strong>
        </template>
      </gl-sprintf>
    </div>
  </gl-modal>
</template>
