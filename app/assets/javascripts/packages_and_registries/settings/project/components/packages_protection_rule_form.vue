<script>
import { GlAlert, GlButton, GlFormGroup, GlForm, GlFormInput, GlFormSelect } from '@gitlab/ui';
import createPackagesProtectionRuleMutation from '~/packages_and_registries/settings/project/graphql/mutations/create_packages_protection_rule.mutation.graphql';
import { s__, __ } from '~/locale';

const PACKAGES_PROTECTION_RULES_SAVED_SUCCESS_MESSAGE = s__('PackageRegistry|Rule saved.');
const PACKAGES_PROTECTION_RULES_SAVED_ERROR_MESSAGE = s__(
  'PackageRegistry|Something went wrong while saving the package protection rule.',
);

const GRAPHQL_ACCESS_LEVEL_VALUE_MAINTAINER = 'MAINTAINER';
const GRAPHQL_ACCESS_LEVEL_VALUE_DEVELOPER = 'DEVELOPER';
const GRAPHQL_ACCESS_LEVEL_VALUE_OWNER = 'OWNER';

export default {
  components: {
    GlButton,
    GlFormInput,
    GlFormSelect,
    GlFormGroup,
    GlAlert,
    GlForm,
  },
  inject: ['projectPath'],
  i18n: {
    PACKAGES_PROTECTION_RULES_SAVED_SUCCESS_MESSAGE,
    PACKAGES_PROTECTION_RULES_SAVED_ERROR_MESSAGE,
  },
  data() {
    return {
      packageProtectionRuleFormData: {
        packageNamePattern: '',
        packageType: 'NPM',
        pushProtectedUpToAccessLevel: GRAPHQL_ACCESS_LEVEL_VALUE_DEVELOPER,
      },
      updateInProgress: false,
      alertErrorMessage: '',
    };
  },
  computed: {
    showLoadingIcon() {
      return this.updateInProgress;
    },
    isEmptyPackageName() {
      return !this.packageProtectionRuleFormData.packageNamePattern;
    },
    isSubmitButtonDisabled() {
      return this.isEmptyPackageName || this.showLoadingIcon;
    },
    isFieldDisabled() {
      return this.showLoadingIcon;
    },
    createPackagesProtectionRuleMutationInput() {
      return {
        projectPath: this.projectPath,
        packageNamePattern: this.packageProtectionRuleFormData.packageNamePattern,
        packageType: this.packageProtectionRuleFormData.packageType,
        pushProtectedUpToAccessLevel: this.packageProtectionRuleFormData
          .pushProtectedUpToAccessLevel,
      };
    },
    packageTypeOptions() {
      return [{ value: 'NPM', text: s__('PackageRegistry|Npm') }];
    },
    pushProtectedUpToAccessLevelOptions() {
      return [
        { value: GRAPHQL_ACCESS_LEVEL_VALUE_DEVELOPER, text: __('Developer') },
        { value: GRAPHQL_ACCESS_LEVEL_VALUE_MAINTAINER, text: __('Maintainer') },
        { value: GRAPHQL_ACCESS_LEVEL_VALUE_OWNER, text: __('Owner') },
      ];
    },
  },
  methods: {
    submit() {
      this.clearAlertErrorMessage();

      this.updateInProgress = true;
      return this.$apollo
        .mutate({
          mutation: createPackagesProtectionRuleMutation,
          variables: {
            input: this.createPackagesProtectionRuleMutationInput,
          },
        })
        .then(({ data }) => {
          const [errorMessage] = data?.createPackagesProtectionRule?.errors ?? [];
          if (errorMessage) {
            this.alertErrorMessage = errorMessage;
            return;
          }

          this.$emit('submit', data.createPackagesProtectionRule.packageProtectionRule);
        })
        .catch(() => {
          this.alertErrorMessage = PACKAGES_PROTECTION_RULES_SAVED_ERROR_MESSAGE;
        })
        .finally(() => {
          this.updateInProgress = false;
        });
    },
    clearAlertErrorMessage() {
      this.alertErrorMessage = null;
    },
    cancelForm() {
      this.clearAlertErrorMessage();
      this.$emit('cancel');
    },
  },
};
</script>

<template>
  <div class="gl-new-card-add-form gl-m-3">
    <gl-form @submit.prevent="submit" @reset="cancelForm">
      <gl-alert
        v-if="alertErrorMessage"
        class="gl-mb-5"
        variant="danger"
        @dismiss="clearAlertErrorMessage"
      >
        {{ alertErrorMessage }}
      </gl-alert>

      <gl-form-group
        :label="s__('PackageRegistry|Name pattern')"
        label-for="input-package-name-pattern"
      >
        <gl-form-input
          id="input-package-name-pattern"
          v-model.trim="packageProtectionRuleFormData.packageNamePattern"
          type="text"
          required
          :disabled="isFieldDisabled"
        />
      </gl-form-group>

      <gl-form-group
        :label="s__('PackageRegistry|Type')"
        label-for="input-package-type"
        :disabled="isFieldDisabled"
      >
        <gl-form-select
          id="input-package-type"
          v-model="packageProtectionRuleFormData.packageType"
          :disabled="isFieldDisabled"
          :options="packageTypeOptions"
          required
        />
      </gl-form-group>

      <gl-form-group
        :label="s__('PackageRegistry|Push protected up to access level')"
        label-for="input-push-protected-up-to-access-level"
        :disabled="isFieldDisabled"
      >
        <gl-form-select
          id="input-push-protected-up-to-access-level"
          v-model="packageProtectionRuleFormData.pushProtectedUpToAccessLevel"
          :options="pushProtectedUpToAccessLevelOptions"
          :disabled="isFieldDisabled"
          required
        />
      </gl-form-group>

      <div class="gl-display-flex gl-justify-content-start">
        <gl-button
          variant="confirm"
          type="submit"
          :disabled="isSubmitButtonDisabled"
          :loading="showLoadingIcon"
          >{{ s__('PackageRegistry|Add rule') }}</gl-button
        >
        <gl-button class="gl-ml-3" type="reset">{{ __('Cancel') }}</gl-button>
      </div>
    </gl-form>
  </div>
</template>
