<script>
import { GlFormGroup, GlFormInput } from '@gitlab/ui';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { visitUrl } from '~/lib/utils/url_utility';
import { logError } from '~/lib/logger';
import { __ } from '~/locale';
import CommitChangesModal from './commit_changes_modal.vue';

const DIR_LABEL = __('Directory name');
const ERROR_MESSAGE = __('Error creating new directory. Please try again.');
const COMMIT_MESSAGE = __('Add new directory');

export default {
  components: {
    GlFormGroup,
    GlFormInput,
    CommitChangesModal,
  },
  i18n: {
    DIR_LABEL,
    ERROR_MESSAGE,
    COMMIT_MESSAGE,
  },
  props: {
    modalId: {
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
    canPushToBranch: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      dir: null,
      loading: false,
    };
  },
  computed: {
    isValid() {
      return Boolean(this.dir);
    },
  },
  methods: {
    submitForm(formData) {
      this.loading = true;

      formData.append('dir_name', this.dir);
      if (!formData.has('branch_name')) {
        formData.append('branch_name', this.originalBranch);
      }

      return axios
        .post(this.path, formData)
        .then((response) => {
          visitUrl(response.data.filePath);
        })
        .catch((e) => {
          this.loading = false;
          logError(
            __('Failed to create a new directory. See exception details for more information.'),
            e,
          );
          createAlert({ message: ERROR_MESSAGE });
        });
    },
  },
};
</script>

<template>
  <commit-changes-modal
    v-bind="$attrs"
    :ref="modalId"
    :loading="loading"
    :valid="isValid"
    :modal-id="modalId"
    :can-push-code="canPushCode"
    :can-push-to-branch="canPushToBranch"
    :commit-message="$options.i18n.COMMIT_MESSAGE"
    :target-branch="targetBranch"
    :original-branch="originalBranch"
    v-on="$listeners"
    @submit-form="submitForm"
  >
    <template #body>
      <gl-form-group :label="$options.i18n.DIR_LABEL" label-for="dir_name">
        <gl-form-input id="dir_name" v-model="dir" :disabled="loading" name="dir_name" />
      </gl-form-group>
    </template>
  </commit-changes-modal>
</template>
