<script>
import {
  GlButton,
  GlForm,
  GlFormCheckbox,
  GlFormInput,
  GlFormGroup,
  GlFormTextarea,
  GlSprintf,
} from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlButton,
    GlForm,
    GlFormCheckbox,
    GlFormInput,
    GlFormGroup,
    GlFormTextarea,
    GlSprintf,
  },
  props: {
    currentBranch: {
      type: String,
      required: false,
      default: '',
    },
    defaultMessage: {
      type: String,
      required: false,
      default: '',
    },
    isSaving: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      message: this.defaultMessage,
      openMergeRequest: false,
      targetBranch: this.currentBranch,
    };
  },
  computed: {
    isCurrentBranchTarget() {
      return this.targetBranch === this.currentBranch;
    },
    submitDisabled() {
      return !(this.message && this.targetBranch);
    },
  },
  methods: {
    onSubmit() {
      this.$emit('submit', {
        message: this.message,
        targetBranch: this.targetBranch,
        openMergeRequest: this.openMergeRequest,
      });
    },
    onReset() {
      this.$emit('cancel');
    },
  },
  i18n: {
    commitMessage: __('Commit message'),
    targetBranch: __('Target Branch'),
    startMergeRequest: __('Start a %{new_merge_request} with these changes'),
    newMergeRequest: __('new merge request'),
    commitChanges: __('Commit changes'),
    cancel: __('Cancel'),
  },
};
</script>

<template>
  <div>
    <gl-form @submit.prevent="onSubmit" @reset.prevent="onReset">
      <gl-form-group
        id="commit-group"
        :label="$options.i18n.commitMessage"
        label-cols-sm="2"
        label-for="commit-message"
      >
        <gl-form-textarea
          id="commit-message"
          v-model="message"
          class="gl-font-monospace!"
          required
          :placeholder="defaultMessage"
        />
      </gl-form-group>
      <gl-form-group
        id="target-branch-group"
        :label="$options.i18n.targetBranch"
        label-cols-sm="2"
        label-for="target-branch-field"
      >
        <gl-form-input
          id="target-branch-field"
          v-model="targetBranch"
          class="gl-font-monospace!"
          required
          data-qa-selector="target_branch_field"
        />
        <gl-form-checkbox
          v-if="!isCurrentBranchTarget"
          v-model="openMergeRequest"
          data-testid="new-mr-checkbox"
          class="gl-mt-3"
        >
          <gl-sprintf :message="$options.i18n.startMergeRequest">
            <template #new_merge_request>
              <strong>{{ $options.i18n.newMergeRequest }}</strong>
            </template>
          </gl-sprintf>
        </gl-form-checkbox>
      </gl-form-group>
      <div
        class="gl-display-flex gl-justify-content-space-between gl-p-5 gl-bg-gray-10 gl-border-t-gray-100 gl-border-t-solid gl-border-t-1"
      >
        <gl-button
          type="submit"
          class="js-no-auto-disable"
          category="primary"
          variant="confirm"
          :disabled="submitDisabled"
          :loading="isSaving"
        >
          {{ $options.i18n.commitChanges }}
        </gl-button>
        <gl-button type="reset" category="secondary" class="gl-mr-3">
          {{ $options.i18n.cancel }}
        </gl-button>
      </div>
    </gl-form>
  </div>
</template>
