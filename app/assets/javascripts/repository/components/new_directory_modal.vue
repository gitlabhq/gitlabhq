<script>
import { GlFormGroup, GlFormInput } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { visitUrl } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import CommitChangesModal from './commit_changes_modal.vue';

const DIR_LABEL = __('Directory name');
const COMMIT_MESSAGE = __('Add new directory');

export default {
  components: {
    GlFormGroup,
    GlFormInput,
    CommitChangesModal,
  },
  i18n: {
    DIR_LABEL,
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
      error: null,
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
      this.error = null;

      formData.append('dir_name', this.dir);
      if (!formData.has('branch_name')) {
        formData.append('branch_name', this.originalBranch);
      }

      return axios
        .post(this.path, formData)
        .then((response) => {
          visitUrl(response.data.filePath);
        })
        .catch(({ response }) => {
          this.error = response?.data?.error;
        })
        .finally(() => {
          this.loading = false;
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
    :error="error"
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
