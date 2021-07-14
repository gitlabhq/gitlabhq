<script>
import { GlModal, GlFormGroup, GlFormInput, GlFormTextarea, GlToggle } from '@gitlab/ui';
import csrf from '~/lib/utils/csrf';
import { __ } from '~/locale';
import {
  SECONDARY_OPTIONS_TEXT,
  COMMIT_LABEL,
  TARGET_BRANCH_LABEL,
  TOGGLE_CREATE_MR_LABEL,
} from '../constants';

export default {
  csrf,
  components: {
    GlModal,
    GlFormGroup,
    GlFormInput,
    GlFormTextarea,
    GlToggle,
  },
  i18n: {
    PRIMARY_OPTIONS_TEXT: __('Delete file'),
    SECONDARY_OPTIONS_TEXT,
    COMMIT_LABEL,
    TARGET_BRANCH_LABEL,
    TOGGLE_CREATE_MR_LABEL,
  },
  props: {
    modalId: {
      type: String,
      required: true,
    },
    modalTitle: {
      type: String,
      required: true,
    },
    deletePath: {
      type: String,
      required: true,
    },
    commitMessage: {
      type: String,
      required: true,
    },
    targetBranch: {
      type: String,
      required: true,
    },
    originalBranch: {
      type: String,
      required: true,
    },
    canPushCode: {
      type: Boolean,
      required: true,
    },
    emptyRepo: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      loading: false,
      commit: this.commitMessage,
      target: this.targetBranch,
      createNewMr: true,
      error: '',
    };
  },
  computed: {
    primaryOptions() {
      return {
        text: this.$options.i18n.PRIMARY_OPTIONS_TEXT,
        attributes: [
          {
            variant: 'danger',
            loading: this.loading,
            disabled: !this.formCompleted || this.loading,
          },
        ],
      };
    },
    cancelOptions() {
      return {
        text: this.$options.i18n.SECONDARY_OPTIONS_TEXT,
        attributes: [
          {
            disabled: this.loading,
          },
        ],
      };
    },
    showCreateNewMrToggle() {
      return this.canPushCode && this.target !== this.originalBranch;
    },
    formCompleted() {
      return this.commit && this.target;
    },
  },
  methods: {
    submitForm(e) {
      e.preventDefault(); // Prevent modal from closing
      this.loading = true;
      this.$refs.form.submit();
    },
  },
};
</script>

<template>
  <gl-modal
    :modal-id="modalId"
    :title="modalTitle"
    :action-primary="primaryOptions"
    :action-cancel="cancelOptions"
    @primary="submitForm"
  >
    <form ref="form" :action="deletePath" method="post">
      <input type="hidden" name="_method" value="delete" />
      <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />
      <template v-if="emptyRepo">
        <!-- Once "empty_repo_upload_experiment" is made available, will need to add class 'js-branch-name'
          Follow-up issue: https://gitlab.com/gitlab-org/gitlab/-/issues/335721 -->
        <input type="hidden" name="branch_name" :value="originalBranch" />
      </template>
      <template v-else>
        <input type="hidden" name="original_branch" :value="originalBranch" />
        <!-- Once "push to branch" permission is made available, will need to add to conditional
          Follow-up issue: https://gitlab.com/gitlab-org/gitlab/-/issues/335462 -->
        <input v-if="createNewMr" type="hidden" name="create_merge_request" value="1" />
        <gl-form-group :label="$options.i18n.COMMIT_LABEL" label-for="commit_message">
          <gl-form-textarea v-model="commit" name="commit_message" :disabled="loading" />
        </gl-form-group>
        <gl-form-group
          v-if="canPushCode"
          :label="$options.i18n.TARGET_BRANCH_LABEL"
          label-for="branch_name"
        >
          <gl-form-input v-model="target" :disabled="loading" name="branch_name" />
        </gl-form-group>
        <gl-toggle
          v-if="showCreateNewMrToggle"
          v-model="createNewMr"
          :disabled="loading"
          :label="$options.i18n.TOGGLE_CREATE_MR_LABEL"
        />
      </template>
    </form>
  </gl-modal>
</template>
