<script>
import { GlModal, GlFormGroup, GlFormInput, GlFormTextarea, GlToggle, GlForm } from '@gitlab/ui';
import csrf from '~/lib/utils/csrf';
import { __ } from '~/locale';
import validation from '~/vue_shared/directives/validation';
import {
  SECONDARY_OPTIONS_TEXT,
  COMMIT_LABEL,
  TARGET_BRANCH_LABEL,
  TOGGLE_CREATE_MR_LABEL,
} from '../constants';

const initFormField = ({ value, required = true, skipValidation = false }) => ({
  value,
  required,
  state: skipValidation ? true : null,
  feedback: null,
});

export default {
  csrf,
  components: {
    GlModal,
    GlFormGroup,
    GlFormInput,
    GlFormTextarea,
    GlToggle,
    GlForm,
  },
  i18n: {
    PRIMARY_OPTIONS_TEXT: __('Delete file'),
    SECONDARY_OPTIONS_TEXT,
    COMMIT_LABEL,
    TARGET_BRANCH_LABEL,
    TOGGLE_CREATE_MR_LABEL,
  },
  directives: {
    validation: validation(),
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
    const form = {
      state: false,
      showValidation: false,
      fields: {
        // fields key must match case of form name for validation directive to work
        commit_message: initFormField({ value: this.commitMessage }),
        branch_name: initFormField({ value: this.targetBranch }),
      },
    };
    return {
      loading: false,
      createNewMr: true,
      error: '',
      form,
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
            disabled: this.loading || !this.form.state,
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
    /* eslint-disable dot-notation */
    showCreateNewMrToggle() {
      return this.canPushCode && this.form.fields['branch_name'].value !== this.originalBranch;
    },
    formCompleted() {
      return this.form.fields['commit_message'].value && this.form.fields['branch_name'].value;
    },
    /* eslint-enable dot-notation */
  },
  methods: {
    submitForm(e) {
      e.preventDefault(); // Prevent modal from closing
      this.form.showValidation = true;

      if (!this.form.state) {
        return;
      }

      this.loading = true;
      this.form.showValidation = false;
      this.$refs.form.$el.submit();
    },
  },
};
</script>

<template>
  <gl-modal
    v-bind="$attrs"
    data-testid="modal-delete"
    :modal-id="modalId"
    :title="modalTitle"
    :action-primary="primaryOptions"
    :action-cancel="cancelOptions"
    @primary="submitForm"
  >
    <gl-form ref="form" novalidate :action="deletePath" method="post">
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
        <gl-form-group
          :label="$options.i18n.COMMIT_LABEL"
          label-for="commit_message"
          :invalid-feedback="form.fields['commit_message'].feedback"
        >
          <gl-form-textarea
            v-model="form.fields['commit_message'].value"
            v-validation:[form.showValidation]
            name="commit_message"
            :state="form.fields['commit_message'].state"
            :disabled="loading"
            required
          />
        </gl-form-group>
        <gl-form-group
          v-if="canPushCode"
          :label="$options.i18n.TARGET_BRANCH_LABEL"
          label-for="branch_name"
          :invalid-feedback="form.fields['branch_name'].feedback"
        >
          <gl-form-input
            v-model="form.fields['branch_name'].value"
            v-validation:[form.showValidation]
            :state="form.fields['branch_name'].state"
            :disabled="loading"
            name="branch_name"
            required
          />
        </gl-form-group>
        <gl-toggle
          v-if="showCreateNewMrToggle"
          v-model="createNewMr"
          :disabled="loading"
          :label="$options.i18n.TOGGLE_CREATE_MR_LABEL"
        />
      </template>
    </gl-form>
  </gl-modal>
</template>
