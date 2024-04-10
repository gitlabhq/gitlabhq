<script>
import { GlAlert, GlButton, GlFormGroup, GlForm, GlFormInput, GlFormSelect } from '@gitlab/ui';
import createProtectionRuleMutation from '~/packages_and_registries/settings/project/graphql/mutations/create_container_protection_rule.mutation.graphql';
import { s__, __ } from '~/locale';

const GRAPHQL_ACCESS_LEVEL_VALUE_MAINTAINER = 'MAINTAINER';
const GRAPHQL_ACCESS_LEVEL_VALUE_DEVELOPER = 'DEVELOPER';
const GRAPHQL_ACCESS_LEVEL_VALUE_OWNER = 'OWNER';

export default {
  components: {
    GlAlert,
    GlButton,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlFormSelect,
  },
  inject: ['projectPath'],
  i18n: {
    protectionRuleSavedErrorMessage: s__(
      'ContainerRegistry|Something went wrong while saving the protection rule.',
    ),
  },
  data() {
    return {
      protectionRuleFormData: {
        repositoryPathPattern: '',
        pushProtectedUpToAccessLevel: GRAPHQL_ACCESS_LEVEL_VALUE_DEVELOPER,
        deleteProtectedUpToAccessLevel: GRAPHQL_ACCESS_LEVEL_VALUE_DEVELOPER,
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
        pushProtectedUpToAccessLevel: this.protectionRuleFormData.pushProtectedUpToAccessLevel,
        deleteProtectedUpToAccessLevel: this.protectionRuleFormData.deleteProtectedUpToAccessLevel,
      };
    },
    protectedUpToAccessLevelOptions() {
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
      </gl-form-group>

      <gl-form-group
        :label="s__('ContainerRegistry|Maximum access level prevented from pushing')"
        label-for="input-push-protected-up-to-access-level"
        :disabled="isFieldDisabled"
      >
        <gl-form-select
          id="input-push-protected-up-to-access-level"
          v-model="protectionRuleFormData.pushProtectedUpToAccessLevel"
          :options="protectedUpToAccessLevelOptions"
          :disabled="isFieldDisabled"
          required
        />
      </gl-form-group>

      <gl-form-group
        :label="s__('ContainerRegistry|Maximum access level prevented from deleting')"
        label-for="input-delete-protected-up-to-access-level"
        :disabled="isFieldDisabled"
      >
        <gl-form-select
          id="input-delete-protected-up-to-access-level"
          v-model="protectionRuleFormData.deleteProtectedUpToAccessLevel"
          :options="protectedUpToAccessLevelOptions"
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
