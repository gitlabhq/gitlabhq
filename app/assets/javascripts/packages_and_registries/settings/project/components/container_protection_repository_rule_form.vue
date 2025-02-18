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
import {
  MinimumAccessLevelOptions,
  GRAPHQL_ACCESS_LEVEL_VALUE_MAINTAINER,
} from '~/packages_and_registries/settings/project/constants';
import { s__ } from '~/locale';

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
  inject: ['projectPath'],
  i18n: {
    protectionRuleSavedErrorMessage: s__(
      'ContainerRegistry|Something went wrong while saving the protection rule.',
    ),
    packageNamePatternInputHelpText: s__(
      'ContainerRegistry|Path pattern with %{linkStart}wildcards%{linkEnd} such as `my-scope/my-container-*` are supported.',
    ),
  },
  data() {
    return {
      protectionRuleFormData: {
        repositoryPathPattern: '',
        minimumAccessLevelForPush: GRAPHQL_ACCESS_LEVEL_VALUE_MAINTAINER,
      },
      updateInProgress: false,
      alertErrorMessages: [],
    };
  },
  computed: {
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
        minimumAccessLevelForPush: this.protectionRuleFormData.minimumAccessLevelForPush,
      };
    },
  },
  methods: {
    submit() {
      this.clearAlertErrorMessages();

      this.updateInProgress = true;
      return this.$apollo
        .mutate({
          mutation: createProtectionRepositoryRuleMutation,
          variables: {
            input: this.createProtectionRepositoryRuleMutationInput,
          },
        })
        .then(({ data }) => {
          const errorMessages = data?.createContainerProtectionRepositoryRule?.errors ?? [];
          if (errorMessages?.length) {
            this.alertErrorMessages = Array.isArray(errorMessages)
              ? errorMessages
              : [errorMessages];
            return;
          }

          this.$emit(
            'submit',
            data.createContainerProtectionRepositoryRule.containerProtectionRepositoryRule,
          );
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
  minimumAccessLevelOptions: MinimumAccessLevelOptions,
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
        :disabled="isFieldDisabled"
      />
      <template #description>
        <gl-sprintf :message="$options.i18n.packageNamePatternInputHelpText">
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
        :options="$options.minimumAccessLevelOptions"
        :disabled="isFieldDisabled"
      />
    </gl-form-group>

    <div class="gl-flex gl-justify-start">
      <gl-button
        variant="confirm"
        type="submit"
        data-testid="add-rule-btn"
        :disabled="isSubmitButtonDisabled"
        :loading="showLoadingIcon"
        >{{ s__('ContainerRegistry|Add rule') }}</gl-button
      >
      <gl-button class="gl-ml-3" type="reset">{{ __('Cancel') }}</gl-button>
    </div>
  </gl-form>
</template>
