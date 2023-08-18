<script>
import { GlFormGroup, GlFormInput, GlModal, GlAlert, GlLink } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { TYPE_ISSUE, TYPE_MERGE_REQUEST } from '~/issues/constants';
import { s__, __, sprintf } from '~/locale';
import issueSetTimeEstimateMutation from '../../queries/issue_set_time_estimate.mutation.graphql';
import mergeRequestSetTimeEstimateMutation from '../../queries/merge_request_set_time_estimate.mutation.graphql';
import { SET_TIME_ESTIMATE_MODAL_ID } from './constants';

const MUTATIONS = {
  [TYPE_ISSUE]: issueSetTimeEstimateMutation,
  [TYPE_MERGE_REQUEST]: mergeRequestSetTimeEstimateMutation,
};

export default {
  components: {
    GlFormGroup,
    GlFormInput,
    GlModal,
    GlAlert,
    GlLink,
  },
  inject: ['issuableType'],
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    issuableIid: {
      type: String,
      required: true,
    },
    /**
     * This object must contain the following keys, used to show
     * the initial time estimate in the form:
     * - timeEstimate: the time estimate numeric value
     * - humanTimeEstimate: the time estimate in human readable format
     */
    timeTracking: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      currentEstimate: this.timeTracking.timeEstimate ?? 0,
      timeEstimate: this.timeTracking.humanTimeEstimate ?? '0h',
      isSaving: false,
      isResetting: false,
      saveError: '',
    };
  },
  computed: {
    submitDisabled() {
      return this.isSaving || this.isResetting || this.timeEstimate === '';
    },
    resetDisabled() {
      return this.isSaving || this.isResetting || this.currentEstimate === 0;
    },
    primaryProps() {
      return {
        text: __('Save'),
        attributes: {
          variant: 'confirm',
          disabled: this.submitDisabled,
          loading: this.isSaving,
        },
      };
    },
    secondaryProps() {
      return this.currentEstimate === 0
        ? null
        : {
            text: __('Remove'),
            attributes: {
              disabled: this.resetDisabled,
              loading: this.isResetting,
            },
          };
    },
    cancelProps() {
      return {
        text: __('Cancel'),
      };
    },
    timeTrackingDocsPath() {
      return helpPagePath('user/project/time_tracking.md');
    },
    modalTitle() {
      return this.currentEstimate === 0
        ? s__('TimeTracking|Set time estimate')
        : s__('TimeTracking|Edit time estimate');
    },
    isIssue() {
      return this.issuableType === TYPE_ISSUE;
    },
    modalText() {
      return sprintf(s__('TimeTracking|Set estimated time to complete this %{issuableTypeName}.'), {
        issuableTypeName: this.isIssue ? __('issue') : __('merge request'),
      });
    },
  },
  watch: {
    timeTracking() {
      this.currentEstimate = this.timeTracking.timeEstimate ?? 0;
      this.timeEstimate = this.timeTracking.humanTimeEstimate ?? '0h';
    },
  },
  methods: {
    resetModal() {
      this.isSaving = false;
      this.isResetting = false;
      this.saveError = '';
    },
    close() {
      this.$refs.modal.close();
    },
    saveTimeEstimate(event) {
      event?.preventDefault();

      if (this.timeEstimate === '') {
        return;
      }

      this.isSaving = true;
      this.updateEstimatedTime(this.timeEstimate);
    },
    resetTimeEstimate() {
      this.isResetting = true;
      this.updateEstimatedTime('0');
    },
    updateEstimatedTime(timeEstimate) {
      this.saveError = '';

      this.$apollo
        .mutate({
          mutation: MUTATIONS[this.issuableType],
          variables: {
            input: {
              projectPath: this.fullPath,
              iid: this.issuableIid,
              timeEstimate,
            },
          },
        })
        .then(({ data }) => {
          if (data.issuableSetTimeEstimate?.errors.length) {
            this.saveError =
              data.issuableSetTimeEstimate.errors[0].message ||
              data.issuableSetTimeEstimate.errors[0];
          } else {
            this.close();
          }
        })
        .catch((error) => {
          this.saveError =
            error?.message || s__('TimeTracking|An error occurred while saving the time estimate.');
        })
        .finally(() => {
          this.isSaving = false;
          this.isResetting = false;
        });
    },
  },
  SET_TIME_ESTIMATE_MODAL_ID,
};
</script>

<template>
  <gl-modal
    ref="modal"
    :title="modalTitle"
    :modal-id="$options.SET_TIME_ESTIMATE_MODAL_ID"
    size="sm"
    data-testid="set-time-estimate-modal"
    :action-primary="primaryProps"
    :action-secondary="secondaryProps"
    :action-cancel="cancelProps"
    @hidden="resetModal"
    @primary.prevent="saveTimeEstimate"
    @secondary.prevent="resetTimeEstimate"
    @cancel="close"
  >
    <p data-testid="timetracking-docs-link">
      {{ modalText }}

      <gl-link :href="timeTrackingDocsPath">{{
        s__('TimeTracking|How do I estimate and track time?')
      }}</gl-link>
    </p>
    <form class="js-quick-submit" @submit.prevent="saveTimeEstimate">
      <gl-form-group
        label-for="time-estimate"
        :label="s__('TimeTracking|Estimate')"
        :description="
          s__(
            `TimeTracking|Enter time as a total duration (for example, 1mo 2w 3d 5h 10m), or specify hours and minutes (for example, 75:30).`,
          )
        "
      >
        <gl-form-input
          id="time-estimate"
          v-model="timeEstimate"
          data-testid="time-estimate"
          autocomplete="off"
        />
      </gl-form-group>
      <gl-alert v-if="saveError" variant="danger" class="gl-mt-5" :dismissible="false">
        {{ saveError }}
      </gl-alert>
      <!-- This is needed to have the quick-submit behaviour (with Ctrl + Enter or Cmd + Enter) -->
      <input type="submit" hidden />
    </form>
  </gl-modal>
</template>
