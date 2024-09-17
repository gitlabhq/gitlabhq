<script>
import { GlButton } from '@gitlab/ui';
import { sprintf } from '~/locale';
import {
  UPDATE_SETTINGS_ERROR_MESSAGE,
  UPDATE_SETTINGS_SUCCESS_MESSAGE,
  KEEP_N_DUPLICATED_PACKAGE_FILES_DESCRIPTION,
  KEEP_N_DUPLICATED_PACKAGE_FILES_FIELDNAME,
  KEEP_N_DUPLICATED_PACKAGE_FILES_LABEL,
  SET_CLEANUP_POLICY_BUTTON,
  READY_FOR_CLEANUP_MESSAGE,
  TIME_TO_NEXT_CLEANUP_MESSAGE,
} from '~/packages_and_registries/settings/project/constants';
import packagesCleanupPolicyQuery from '~/packages_and_registries/settings/project/graphql/queries/get_packages_cleanup_policy.query.graphql';
import updatePackagesCleanupPolicyMutation from '~/packages_and_registries/settings/project/graphql/mutations/update_packages_cleanup_policy.mutation.graphql';
import { formOptionsGenerator } from '~/packages_and_registries/settings/project/utils';
import Tracking from '~/tracking';
import { approximateDuration, calculateRemainingMilliseconds } from '~/lib/utils/datetime_utility';
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
    TIME_TO_NEXT_CLEANUP_MESSAGE,
    READY_FOR_CLEANUP_MESSAGE,
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
    nextCleanupMessage() {
      const { nextRunAt } = this.value;
      const difference = calculateRemainingMilliseconds(nextRunAt);
      return difference
        ? sprintf(TIME_TO_NEXT_CLEANUP_MESSAGE, {
            nextRunAt: approximateDuration(difference / 1000),
          })
        : READY_FOR_CLEANUP_MESSAGE;
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
          awaitRefetchQueries: true,
          refetchQueries: [
            {
              query: packagesCleanupPolicyQuery,
              variables: {
                projectPath: this.projectPath,
              },
            },
          ],
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
    <expiration-dropdown
      :value="prefilledForm.keepNDuplicatedPackageFiles"
      :disabled="isFieldDisabled"
      :form-options="$options.formOptions.keepNDuplicatedPackageFiles"
      :label="$options.i18n.KEEP_N_DUPLICATED_PACKAGE_FILES_LABEL"
      :description="$options.i18n.KEEP_N_DUPLICATED_PACKAGE_FILES_DESCRIPTION"
      dropdown-class="md:gl-max-w-1/2"
      name="keep-n-duplicated-package-files"
      data-testid="keep-n-duplicated-package-files-dropdown"
      @input="onModelChange($event, 'keepNDuplicatedPackageFiles')"
    />
    <p v-if="value.nextRunAt" data-testid="next-run-at">
      {{ nextCleanupMessage }}
    </p>
    <div class="gl-mt-6 gl-flex gl-items-center">
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
