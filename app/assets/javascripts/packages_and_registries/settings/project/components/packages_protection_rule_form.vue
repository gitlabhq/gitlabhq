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
import { s__, __ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

const PACKAGES_PROTECTION_RULES_SAVED_SUCCESS_MESSAGE = s__('PackageRegistry|Rule saved.');
const PACKAGES_PROTECTION_RULES_SAVED_ERROR_MESSAGE = s__(
  'PackageRegistry|Something went wrong while saving the package protection rule.',
);

const GRAPHQL_ACCESS_LEVEL_VALUE_MAINTAINER = 'MAINTAINER';
const GRAPHQL_ACCESS_LEVEL_VALUE_OWNER = 'OWNER';
const GRAPHQL_ACCESS_LEVEL_VALUE_ADMIN = 'ADMIN';

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
  i18n: {
    PACKAGES_PROTECTION_RULES_SAVED_SUCCESS_MESSAGE,
    PACKAGES_PROTECTION_RULES_SAVED_ERROR_MESSAGE,
    packageNamePatternInputHelpText: s__(
      'PackageRegistry|%{linkStart}Wildcards%{linkEnd} such as `my-package-*` are supported.',
    ),
  },
  data() {
    return {
      packageProtectionRuleFormData: {
        packageNamePattern: '',
        packageType: 'NPM',
        minimumAccessLevelForPush: GRAPHQL_ACCESS_LEVEL_VALUE_MAINTAINER,
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
        minimumAccessLevelForPush: this.packageProtectionRuleFormData.minimumAccessLevelForPush,
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

      return packageTypeOptions.sort((a, b) => a.text.localeCompare(b.text));
    },
    minimumAccessLevelForPushOptions() {
      return [
        { value: GRAPHQL_ACCESS_LEVEL_VALUE_MAINTAINER, text: __('Maintainer') },
        { value: GRAPHQL_ACCESS_LEVEL_VALUE_OWNER, text: __('Owner') },
        { value: GRAPHQL_ACCESS_LEVEL_VALUE_ADMIN, text: s__('AdminUsers|Administrator') },
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
        :options="minimumAccessLevelForPushOptions"
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
        data-testid="add-rule-btn"
        >{{ s__('PackageRegistry|Add rule') }}</gl-button
      >
      <gl-button class="gl-ml-3" type="reset">{{ __('Cancel') }}</gl-button>
    </div>
  </gl-form>
</template>
