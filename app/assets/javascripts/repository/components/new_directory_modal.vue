<script>
import {
  GlAlert,
  GlForm,
  GlModal,
  GlFormGroup,
  GlFormInput,
  GlFormTextarea,
  GlToggle,
} from '@gitlab/ui';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { visitUrl } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import {
  SECONDARY_OPTIONS_TEXT,
  COMMIT_LABEL,
  TARGET_BRANCH_LABEL,
  TOGGLE_CREATE_MR_LABEL,
  NEW_BRANCH_IN_FORK,
} from '../constants';

const MODAL_TITLE = __('Create New Directory');
const PRIMARY_OPTIONS_TEXT = __('Create directory');
const DIR_LABEL = __('Directory name');
const ERROR_MESSAGE = __('Error creating new directory. Please try again.');

export default {
  components: {
    GlAlert,
    GlModal,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlFormTextarea,
    GlToggle,
  },
  i18n: {
    DIR_LABEL,
    COMMIT_LABEL,
    TARGET_BRANCH_LABEL,
    TOGGLE_CREATE_MR_LABEL,
    NEW_BRANCH_IN_FORK,
    PRIMARY_OPTIONS_TEXT,
    ERROR_MESSAGE,
  },
  props: {
    modalTitle: {
      type: String,
      default: MODAL_TITLE,
      required: false,
    },
    modalId: {
      type: String,
      required: true,
    },
    primaryBtnText: {
      type: String,
      default: PRIMARY_OPTIONS_TEXT,
      required: false,
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
    path: {
      type: String,
      required: true,
    },
    canPushCode: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      dir: null,
      commit: this.commitMessage,
      target: this.targetBranch,
      createNewMr: true,
      loading: false,
    };
  },
  computed: {
    primaryOptions() {
      return {
        text: this.primaryBtnText,
        attributes: {
          variant: 'confirm',
          loading: this.loading,
          disabled: !this.formCompleted || this.loading,
        },
      };
    },
    cancelOptions() {
      return {
        text: SECONDARY_OPTIONS_TEXT,
        attributes: {
          disabled: this.loading,
        },
      };
    },
    showCreateNewMrToggle() {
      return this.canPushCode;
    },
    formCompleted() {
      return this.dir && this.commit && this.target;
    },
  },
  methods: {
    submitForm() {
      this.loading = true;

      const formData = new FormData();
      formData.append('dir_name', this.dir);
      formData.append('commit_message', this.commit);
      formData.append('branch_name', this.target);
      formData.append('original_branch', this.originalBranch);

      if (this.createNewMr) {
        formData.append('create_merge_request', this.createNewMr);
      }

      return axios
        .post(this.path, formData)
        .then((response) => {
          visitUrl(response.data.filePath);
        })
        .catch(() => {
          this.loading = false;
          createAlert({ message: ERROR_MESSAGE });
        });
    },
  },
};
</script>

<template>
  <gl-form>
    <gl-modal
      :modal-id="modalId"
      :title="modalTitle"
      :action-primary="primaryOptions"
      :action-cancel="cancelOptions"
      @primary.prevent="submitForm"
    >
      <gl-form-group :label="$options.i18n.DIR_LABEL" label-for="dir_name">
        <gl-form-input v-model="dir" :disabled="loading" name="dir_name" />
      </gl-form-group>
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
      <gl-alert v-if="!canPushCode" variant="info" :dismissible="false" class="gl-mt-3">
        {{ $options.i18n.NEW_BRANCH_IN_FORK }}
      </gl-alert>
    </gl-modal>
  </gl-form>
</template>
