<script>
import {
  GlAlert,
  GlButton,
  GlFormGroup,
  GlForm,
  GlFormInput,
  GlFormSelect,
  GlSprintf,
} from '@gitlab/ui';
import HelpPageLink from '~/vue_shared/components/help_page_link/help_page_link.vue';
import createPackagesProtectionRuleMutation from '~/packages_and_registries/settings/project/graphql/mutations/create_packages_protection_rule.mutation.graphql';
import updatePackagesProtectionRuleMutation from '~/packages_and_registries/settings/project/graphql/mutations/update_packages_protection_rule.mutation.graphql';
import { s__, __ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import {
  MinimumAccessLevelOptions,
  GRAPHQL_ACCESS_LEVEL_VALUE_MAINTAINER,
} from '~/packages_and_registries/settings/project/constants';

const PACKAGES_PROTECTION_RULES_SAVED_ERROR_MESSAGE = s__(
  'PackageRegistry|Something went wrong while saving the package protection rule.',
);

export default {
  components: {
    GlButton,
    GlFormInput,
    GlFormSelect,
    GlFormGroup,
    GlAlert,
    GlForm,
    GlSprintf,
    HelpPageLink,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: ['projectPath'],
  props: {
    rule: {
      type: Object,
      required: false,
      default: null,
    },
  },
  i18n: {
    PACKAGES_PROTECTION_RULES_SAVED_ERROR_MESSAGE,
    packageNamePatternInputHelpText: s__(
      'PackageRegistry|%{linkStart}Wildcards%{linkEnd} such as `my-package-*` are supported.',
    ),
  },
  data() {
    return {
      packageProtectionRuleFormData: {
        packageNamePattern: this.rule?.packageNamePattern ?? '',
        packageType: this.rule?.packageType ?? 'NPM',
        minimumAccessLevelForPush:
          this.rule?.minimumAccessLevelForPush ?? GRAPHQL_ACCESS_LEVEL_VALUE_MAINTAINER,
      },
      updateInProgress: false,
      alertErrorMessage: '',
    };
  },
  computed: {
    mutation() {
      return this.rule
        ? updatePackagesProtectionRuleMutation
        : createPackagesProtectionRuleMutation;
    },
    mutationKey() {
      return this.rule ? 'updatePackagesProtectionRule' : 'createPackagesProtectionRule';
    },
    showLoadingIcon() {
      return this.updateInProgress;
    },
    submitButtonText() {
      return this.rule ? __('Save changes') : s__('PackageRegistry|Add rule');
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
        ...this.packageProtectionRuleFormData,
      };
    },
    updatePackagesProtectionRuleMutationInput() {
      return {
        id: this.rule?.id,
        ...this.packageProtectionRuleFormData,
      };
    },
    packageTypeOptions() {
      const packageTypeOptions = [
        { value: 'NPM', text: s__('PackageRegistry|Npm') },
        { value: 'PYPI', text: s__('PackageRegistry|PyPI') },
      ];

      if (this.glFeatures.packagesProtectedPackagesConan) {
        packageTypeOptions.push({ value: 'CONAN', text: s__('PackageRegistry|Conan') });
      }

      if (this.glFeatures.packagesProtectedPackagesMaven) {
        packageTypeOptions.push({ value: 'MAVEN', text: s__('PackageRegistry|Maven') });
      }

      return packageTypeOptions.sort((a, b) => a.text.localeCompare(b.text));
    },
  },
  methods: {
    submit() {
      this.clearAlertErrorMessage();

      this.updateInProgress = true;
      const input = this.rule
        ? this.updatePackagesProtectionRuleMutationInput
        : this.createPackagesProtectionRuleMutationInput;

      return this.$apollo
        .mutate({
          mutation: this.mutation,
          variables: {
            input,
          },
        })
        .then(({ data }) => {
          const [errorMessage] = data?.[this.mutationKey]?.errors ?? [];
          if (errorMessage) {
            this.alertErrorMessage = errorMessage;
            return;
          }

          this.$emit('submit', data[this.mutationKey].packageProtectionRule);
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
  minimumAccessLevelForPushOptions: MinimumAccessLevelOptions,
};
</script>

<template>
  <gl-form data-testid="packages-protection-rule-form" @submit.prevent="submit" @reset="cancelForm">
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
      <template #description>
        <gl-sprintf :message="$options.i18n.packageNamePatternInputHelpText">
          <template #link="{ content }">
            <help-page-link
              href="user/packages/package_registry/package_protection_rules.md"
              target="_blank"
              >{{ content }}</help-page-link
            >
          </template>
        </gl-sprintf>
      </template>
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
      :label="s__('PackageRegistry|Minimum access level for push')"
      label-for="input-minimum-access-level-for-push"
      :disabled="isFieldDisabled"
    >
      <gl-form-select
        id="input-minimum-access-level-for-push"
        v-model="packageProtectionRuleFormData.minimumAccessLevelForPush"
        :options="$options.minimumAccessLevelForPushOptions"
        :disabled="isFieldDisabled"
        required
      />
    </gl-form-group>

    <div class="gl-flex gl-justify-start">
      <gl-button
        variant="confirm"
        type="submit"
        :disabled="isSubmitButtonDisabled"
        :loading="showLoadingIcon"
        data-testid="submit-btn"
        >{{ submitButtonText }}</gl-button
      >
      <gl-button class="gl-ml-3" type="reset">{{ __('Cancel') }}</gl-button>
    </div>
  </gl-form>
</template>
