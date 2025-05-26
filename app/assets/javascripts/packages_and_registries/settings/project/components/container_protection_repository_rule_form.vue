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
import createProtectionRepositoryRuleMutation from '~/packages_and_registries/settings/project/graphql/mutations/create_container_protection_repository_rule.mutation.graphql';
import updateProtectionRepositoryRuleMutation from '~/packages_and_registries/settings/project/graphql/mutations/update_container_protection_repository_rule.mutation.graphql';
import {
  ContainerRepositoryMinimumAccessLevelOptions,
  GRAPHQL_ACCESS_LEVEL_VALUE_MAINTAINER,
  GRAPHQL_ACCESS_LEVEL_VALUE_NULL,
} from '~/packages_and_registries/settings/project/constants';
import { s__, __ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  components: {
    GlAlert,
    GlButton,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlFormSelect,
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
    protectionRuleSavedErrorMessage: s__(
      'ContainerRegistry|Something went wrong while saving the protection rule.',
    ),
    repositoryPathPatternInputHelpText: s__(
      'ContainerRegistry|Path pattern with %{linkStart}wildcards%{linkEnd} such as `my-scope/my-container-*` are supported.',
    ),
  },
  data() {
    return {
      protectionRuleFormData: {
        repositoryPathPattern: this.rule?.repositoryPathPattern ?? '',
        minimumAccessLevelForDelete: this.isExistingRule()
          ? this.rule.minimumAccessLevelForDelete ?? GRAPHQL_ACCESS_LEVEL_VALUE_NULL
          : GRAPHQL_ACCESS_LEVEL_VALUE_MAINTAINER,
        minimumAccessLevelForPush: this.isExistingRule()
          ? this.rule.minimumAccessLevelForPush ?? GRAPHQL_ACCESS_LEVEL_VALUE_NULL
          : GRAPHQL_ACCESS_LEVEL_VALUE_MAINTAINER,
      },
      updateInProgress: false,
      alertErrorMessages: [],
    };
  },
  computed: {
    mutation() {
      return this.isExistingRule()
        ? updateProtectionRepositoryRuleMutation
        : createProtectionRepositoryRuleMutation;
    },
    mutationKey() {
      return this.isExistingRule()
        ? 'updateContainerProtectionRepositoryRule'
        : 'createContainerProtectionRepositoryRule';
    },
    mutationInput() {
      return this.isExistingRule()
        ? this.updateProtectionRepositoryRuleMutationInput
        : this.createProtectionRepositoryRuleMutationInput;
    },
    submitButtonText() {
      return this.isExistingRule() ? __('Save changes') : s__('ContainerRegistry|Add rule');
    },
    showLoadingIcon() {
      return this.updateInProgress;
    },
    isEmptyRepositoryPathPattern() {
      return !this.protectionRuleFormData.repositoryPathPattern;
    },
    isSubmitButtonDisabled() {
      return this.isEmptyRepositoryPathPattern || this.showLoadingIcon;
    },
    isFieldDisabled() {
      return this.showLoadingIcon;
    },
    createProtectionRepositoryRuleMutationInput() {
      return {
        projectPath: this.projectPath,
        repositoryPathPattern: this.protectionRuleFormData.repositoryPathPattern,
        minimumAccessLevelForDelete:
          this.protectionRuleFormData.minimumAccessLevelForDelete || null,
        minimumAccessLevelForPush: this.protectionRuleFormData.minimumAccessLevelForPush || null,
      };
    },
    updateProtectionRepositoryRuleMutationInput() {
      return {
        id: this.rule?.id,
        ...this.protectionRuleFormData,
        minimumAccessLevelForDelete:
          this.protectionRuleFormData.minimumAccessLevelForDelete || null,
        minimumAccessLevelForPush: this.protectionRuleFormData.minimumAccessLevelForPush || null,
      };
    },
    containerRepositoryMinimumAccessLevelOptions() {
      return this.glFeatures.containerRegistryProtectedContainersDelete
        ? this.$options.containerRepositoryMinimumAccessLevelOptions
        : this.$options.containerRepositoryMinimumAccessLevelOptions.filter((option) =>
            Boolean(option.value),
          );
    },
  },
  methods: {
    isExistingRule() {
      return Boolean(this.rule);
    },
    submit() {
      this.clearAlertErrorMessages();

      this.updateInProgress = true;

      return this.$apollo
        .mutate({
          mutation: this.mutation,
          variables: {
            input: this.mutationInput,
          },
        })
        .then(({ data }) => {
          const errorMessages = data?.[this.mutationKey]?.errors ?? [];
          if (errorMessages?.length) {
            this.alertErrorMessages = Array.isArray(errorMessages)
              ? errorMessages
              : [errorMessages];
            return;
          }

          this.$emit('submit', data[this.mutationKey].containerProtectionRepositoryRule);
        })
        .catch(() => {
          this.alertErrorMessages = [this.$options.i18n.protectionRuleSavedErrorMessage];
        })
        .finally(() => {
          this.updateInProgress = false;
        });
    },
    clearAlertErrorMessages() {
      this.alertErrorMessages = [];
    },
    cancelForm() {
      this.clearAlertErrorMessages();
      this.$emit('cancel');
    },
  },
  containerRepositoryMinimumAccessLevelOptions: ContainerRepositoryMinimumAccessLevelOptions,
};
</script>

<template>
  <gl-form @submit.prevent="submit" @reset="cancelForm">
    <gl-alert
      v-if="alertErrorMessages.length"
      class="gl-mb-5"
      variant="danger"
      @dismiss="clearAlertErrorMessages"
    >
      <div v-for="error in alertErrorMessages" :key="error">{{ error }}</div>
    </gl-alert>

    <gl-form-group
      :label="s__('ContainerRegistry|Repository path pattern')"
      label-for="input-repository-path-pattern"
    >
      <gl-form-input
        id="input-repository-path-pattern"
        v-model.trim="protectionRuleFormData.repositoryPathPattern"
        type="text"
        required
        autofocus
        :disabled="isFieldDisabled"
      />
      <template #description>
        <gl-sprintf :message="$options.i18n.repositoryPathPatternInputHelpText">
          <template #link="{ content }">
            <help-page-link
              href="user/packages/container_registry/container_repository_protection_rules.md"
              target="_blank"
              >{{ content }}</help-page-link
            >
          </template>
        </gl-sprintf>
      </template>
    </gl-form-group>

    <gl-form-group
      :label="s__('ContainerRegistry|Minimum access level for push')"
      label-for="input-minimum-access-level-for-push"
      :disabled="isFieldDisabled"
    >
      <gl-form-select
        id="input-minimum-access-level-for-push"
        v-model="protectionRuleFormData.minimumAccessLevelForPush"
        :options="containerRepositoryMinimumAccessLevelOptions"
        :disabled="isFieldDisabled"
      />
    </gl-form-group>

    <gl-form-group
      v-if="glFeatures.containerRegistryProtectedContainersDelete"
      :label="s__('ContainerRegistry|Minimum access level for delete')"
      label-for="input-minimum-access-level-for-delete"
      :disabled="isFieldDisabled"
    >
      <gl-form-select
        id="input-minimum-access-level-for-delete"
        v-model="protectionRuleFormData.minimumAccessLevelForDelete"
        :options="containerRepositoryMinimumAccessLevelOptions"
        :disabled="isFieldDisabled"
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
