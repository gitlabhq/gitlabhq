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
import createProtectionRuleMutation from '~/packages_and_registries/settings/project/graphql/mutations/create_container_protection_rule.mutation.graphql';
import { s__, __ } from '~/locale';

const GRAPHQL_ACCESS_LEVEL_VALUE_MAINTAINER = 'MAINTAINER';
const GRAPHQL_ACCESS_LEVEL_VALUE_OWNER = 'OWNER';
const GRAPHQL_ACCESS_LEVEL_VALUE_ADMIN = 'ADMIN';

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
        minimumAccessLevelForDelete: GRAPHQL_ACCESS_LEVEL_VALUE_MAINTAINER,
      },
      updateInProgress: false,
      alertErrorMessage: '',
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
    createProtectionRuleMutationInput() {
      return {
        projectPath: this.projectPath,
        repositoryPathPattern: this.protectionRuleFormData.repositoryPathPattern,
        minimumAccessLevelForPush: this.protectionRuleFormData.minimumAccessLevelForPush,
        minimumAccessLevelForDelete: this.protectionRuleFormData.minimumAccessLevelForDelete,
      };
    },
    minimumAccessLevelOptions() {
      return [
        { value: GRAPHQL_ACCESS_LEVEL_VALUE_MAINTAINER, text: __('Maintainer') },
        { value: GRAPHQL_ACCESS_LEVEL_VALUE_OWNER, text: __('Owner') },
        { value: GRAPHQL_ACCESS_LEVEL_VALUE_ADMIN, text: __('Admin') },
      ];
    },
  },
  methods: {
    submit() {
      this.clearAlertErrorMessage();

      this.updateInProgress = true;
      return this.$apollo
        .mutate({
          mutation: createProtectionRuleMutation,
          variables: {
            input: this.createProtectionRuleMutationInput,
          },
        })
        .then(({ data }) => {
          const [errorMessage] = data?.createContainerRegistryProtectionRule?.errors ?? [];
          if (errorMessage) {
            this.alertErrorMessage = errorMessage;
            return;
          }

          this.$emit(
            'submit',
            data.createContainerRegistryProtectionRule.containerRegistryProtectionRule,
          );
        })
        .catch(() => {
          this.alertErrorMessage = this.$options.i18n.protectionRuleSavedErrorMessage;
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
                href="user/packages/container_registry/container_protection_rules.md"
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
          :options="minimumAccessLevelOptions"
          :disabled="isFieldDisabled"
          required
        />
      </gl-form-group>

      <gl-form-group
        :label="s__('ContainerRegistry|Minimum access level for delete')"
        label-for="input-minimum-access-level-for-delete"
        :disabled="isFieldDisabled"
      >
        <gl-form-select
          id="input-minimum-access-level-for-delete"
          v-model="protectionRuleFormData.minimumAccessLevelForDelete"
          :options="minimumAccessLevelOptions"
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
          >{{ s__('ContainerRegistry|Add rule') }}</gl-button
        >
        <gl-button class="gl-ml-3" type="reset">{{ __('Cancel') }}</gl-button>
      </div>
    </gl-form>
  </div>
</template>
