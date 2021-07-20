<script>
import { GlFormGroup, GlButton, GlFormInput, GlForm, GlAlert } from '@gitlab/ui';
import {
  CREATE_BRANCH_ERROR_GENERIC,
  CREATE_BRANCH_ERROR_WITH_CONTEXT,
  CREATE_BRANCH_SUCCESS_ALERT,
  I18N_NEW_BRANCH_PAGE_TITLE,
  I18N_NEW_BRANCH_LABEL_DROPDOWN,
  I18N_NEW_BRANCH_LABEL_BRANCH,
  I18N_NEW_BRANCH_LABEL_SOURCE,
  I18N_NEW_BRANCH_SUBMIT_BUTTON_TEXT,
} from '../constants';
import createBranchMutation from '../graphql/mutations/create_branch.mutation.graphql';
import ProjectDropdown from './project_dropdown.vue';
import SourceBranchDropdown from './source_branch_dropdown.vue';

const DEFAULT_ALERT_VARIANT = 'danger';
const DEFAULT_ALERT_PARAMS = {
  title: '',
  message: '',
  variant: DEFAULT_ALERT_VARIANT,
  primaryButtonLink: '',
  primaryButtonText: '',
};

export default {
  name: 'JiraConnectNewBranch',
  components: {
    GlFormGroup,
    GlButton,
    GlFormInput,
    GlForm,
    GlAlert,
    ProjectDropdown,
    SourceBranchDropdown,
  },
  props: {
    initialBranchName: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      selectedProject: null,
      selectedSourceBranchName: null,
      branchName: this.initialBranchName,
      createBranchLoading: false,
      alertParams: {
        ...DEFAULT_ALERT_PARAMS,
      },
    };
  },
  computed: {
    selectedProjectId() {
      return this.selectedProject?.id;
    },
    showAlert() {
      return Boolean(this.alertParams?.message);
    },
    disableSubmitButton() {
      return !(this.selectedProject && this.selectedSourceBranchName && this.branchName);
    },
  },
  methods: {
    displayAlert({ title, message, variant = DEFAULT_ALERT_VARIANT } = {}) {
      this.alertParams = {
        title,
        message,
        variant,
      };
    },
    onAlertDismiss() {
      this.alertParams = {
        ...DEFAULT_ALERT_PARAMS,
      };
    },
    onProjectSelect(project) {
      this.selectedProject = project;
      this.selectedSourceBranchName = null; // reset branch selection
    },
    onSourceBranchSelect(branchName) {
      this.selectedSourceBranchName = branchName;
    },
    onError({ title, message } = {}) {
      this.displayAlert({
        message,
        title,
      });
    },
    onSubmit() {
      this.createBranch();
    },
    async createBranch() {
      this.createBranchLoading = true;

      try {
        const { data } = await this.$apollo.mutate({
          mutation: createBranchMutation,
          variables: {
            name: this.branchName,
            ref: this.selectedSourceBranchName,
            projectPath: this.selectedProject.fullPath,
          },
        });
        const { errors } = data.createBranch;
        if (errors.length > 0) {
          this.onError({
            title: CREATE_BRANCH_ERROR_WITH_CONTEXT,
            message: errors[0],
          });
        } else {
          this.displayAlert({
            ...CREATE_BRANCH_SUCCESS_ALERT,
            variant: 'success',
          });
        }
      } catch (e) {
        this.onError({
          message: CREATE_BRANCH_ERROR_GENERIC,
        });
      }

      this.createBranchLoading = false;
    },
  },
  i18n: {
    I18N_NEW_BRANCH_PAGE_TITLE,
    I18N_NEW_BRANCH_LABEL_DROPDOWN,
    I18N_NEW_BRANCH_LABEL_BRANCH,
    I18N_NEW_BRANCH_LABEL_SOURCE,
    I18N_NEW_BRANCH_SUBMIT_BUTTON_TEXT,
  },
};
</script>

<template>
  <div>
    <div class="gl-border-1 gl-border-b-solid gl-border-gray-100 gl-mb-5 gl-mt-7">
      <h1 class="page-title">
        {{ $options.i18n.I18N_NEW_BRANCH_PAGE_TITLE }}
      </h1>
    </div>

    <gl-alert
      v-if="showAlert"
      class="gl-mb-5"
      :variant="alertParams.variant"
      :title="alertParams.title"
      @dismiss="onAlertDismiss"
    >
      {{ alertParams.message }}
    </gl-alert>

    <gl-form @submit.prevent="onSubmit">
      <gl-form-group
        :label="$options.i18n.I18N_NEW_BRANCH_LABEL_DROPDOWN"
        label-for="project-select"
      >
        <project-dropdown
          id="project-select"
          :selected-project="selectedProject"
          @change="onProjectSelect"
          @error="onError"
        />
      </gl-form-group>

      <gl-form-group
        :label="$options.i18n.I18N_NEW_BRANCH_LABEL_BRANCH"
        label-for="branch-name-input"
      >
        <gl-form-input id="branch-name-input" v-model="branchName" type="text" required />
      </gl-form-group>

      <gl-form-group
        :label="$options.i18n.I18N_NEW_BRANCH_LABEL_SOURCE"
        label-for="source-branch-select"
      >
        <source-branch-dropdown
          id="source-branch-select"
          :selected-project="selectedProject"
          :selected-branch-name="selectedSourceBranchName"
          @change="onSourceBranchSelect"
          @error="onError"
        />
      </gl-form-group>

      <div class="form-actions">
        <gl-button
          :loading="createBranchLoading"
          type="submit"
          variant="confirm"
          :disabled="disableSubmitButton"
        >
          {{ $options.i18n.I18N_NEW_BRANCH_SUBMIT_BUTTON_TEXT }}
        </gl-button>
      </div>
    </gl-form>
  </div>
</template>
