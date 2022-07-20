<script>
import { GlButton } from '@gitlab/ui';
import {
  UPDATE_SETTINGS_ERROR_MESSAGE,
  UPDATE_SETTINGS_SUCCESS_MESSAGE,
  SET_CLEANUP_POLICY_BUTTON,
  KEEP_N_DUPLICATED_PACKAGE_FILES_DESCRIPTION,
  KEEP_N_DUPLICATED_PACKAGE_FILES_FIELDNAME,
  KEEP_N_DUPLICATED_PACKAGE_FILES_LABEL,
} from '~/packages_and_registries/settings/project/constants';
import updatePackagesCleanupPolicyMutation from '~/packages_and_registries/settings/project/graphql/mutations/update_packages_cleanup_policy.mutation.graphql';
import { formOptionsGenerator } from '~/packages_and_registries/settings/project/utils';
import Tracking from '~/tracking';
import ExpirationDropdown from './expiration_dropdown.vue';

export default {
  components: {
    GlButton,
    ExpirationDropdown,
  },
  mixins: [Tracking.mixin()],
  inject: ['projectPath'],
  props: {
    value: {
      type: Object,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  formOptions: formOptionsGenerator(),
  i18n: {
    KEEP_N_DUPLICATED_PACKAGE_FILES_LABEL,
    KEEP_N_DUPLICATED_PACKAGE_FILES_DESCRIPTION,
    SET_CLEANUP_POLICY_BUTTON,
  },
  data() {
    return {
      tracking: {
        label: 'packages_cleanup_policies',
      },
      mutationLoading: false,
    };
  },
  computed: {
    prefilledForm() {
      return {
        ...this.value,
        keepNDuplicatedPackageFiles: this.findDefaultOption(
          KEEP_N_DUPLICATED_PACKAGE_FILES_FIELDNAME,
        ),
      };
    },
    showLoadingIcon() {
      return this.isLoading || this.mutationLoading;
    },
    isSubmitButtonDisabled() {
      return this.showLoadingIcon;
    },
    isFieldDisabled() {
      return this.showLoadingIcon;
    },
    mutationVariables() {
      return {
        projectPath: this.projectPath,
        keepNDuplicatedPackageFiles: this.prefilledForm.keepNDuplicatedPackageFiles,
      };
    },
  },
  methods: {
    findDefaultOption(option) {
      return this.value[option] || this.$options.formOptions[option].find((f) => f.default)?.key;
    },
    submit() {
      this.track('submit_packages_cleanup_form');
      this.mutationLoading = true;
      return this.$apollo
        .mutate({
          mutation: updatePackagesCleanupPolicyMutation,
          variables: {
            input: this.mutationVariables,
          },
        })
        .then(({ data }) => {
          const [errorMessage] = data?.updatePackagesCleanupPolicy?.errors ?? [];
          if (errorMessage) {
            throw errorMessage;
          } else {
            this.$toast.show(UPDATE_SETTINGS_SUCCESS_MESSAGE);
          }
        })
        .catch(() => {
          this.$toast.show(UPDATE_SETTINGS_ERROR_MESSAGE);
        })
        .finally(() => {
          this.mutationLoading = false;
        });
    },
    onModelChange(newValue, model) {
      this.$emit('input', { ...this.value, [model]: newValue });
    },
  },
};
</script>

<template>
  <form ref="form-element" @submit.prevent="submit">
    <div class="gl-md-max-w-50p">
      <expiration-dropdown
        v-model="prefilledForm.keepNDuplicatedPackageFiles"
        :disabled="isFieldDisabled"
        :form-options="$options.formOptions.keepNDuplicatedPackageFiles"
        :label="$options.i18n.KEEP_N_DUPLICATED_PACKAGE_FILES_LABEL"
        :description="$options.i18n.KEEP_N_DUPLICATED_PACKAGE_FILES_DESCRIPTION"
        name="keep-n-duplicated-package-files"
        data-testid="keep-n-duplicated-package-files-dropdown"
        @input="onModelChange($event, 'keepNDuplicatedPackageFiles')"
      />
    </div>
    <div class="gl-mt-7 gl-display-flex gl-align-items-center">
      <gl-button
        data-testid="save-button"
        type="submit"
        :disabled="isSubmitButtonDisabled"
        :loading="showLoadingIcon"
        category="primary"
        variant="confirm"
        class="js-no-auto-disable gl-mr-4"
      >
        {{ $options.i18n.SET_CLEANUP_POLICY_BUTTON }}
      </gl-button>
    </div>
  </form>
</template>
