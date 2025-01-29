<script>
import {
  GlAlert,
  GlButton,
  GlFormGroup,
  GlForm,
  GlFormInput,
  GlFormSelect,
  GlLink,
  GlSprintf,
} from '@gitlab/ui';
import createProtectionTagRuleMutation from '~/packages_and_registries/settings/project/graphql/mutations/create_container_protection_tag_rule.mutation.graphql';
import {
  MinimumAccessLevelOptions,
  GRAPHQL_ACCESS_LEVEL_VALUE_MAINTAINER,
} from '~/packages_and_registries/settings/project/constants';
import { s__ } from '~/locale';
import { InternalEvents } from '~/tracking';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

export default {
  components: {
    GlAlert,
    GlButton,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlFormSelect,
    GlLink,
    GlSprintf,
  },
  mixins: [InternalEvents.mixin()],
  inject: ['projectPath'],
  data() {
    return {
      alertErrorMessages: [],
      protectionRuleFormData: {
        tagNamePattern: '',
        minimumAccessLevelForPush: GRAPHQL_ACCESS_LEVEL_VALUE_MAINTAINER,
        minimumAccessLevelForDelete: GRAPHQL_ACCESS_LEVEL_VALUE_MAINTAINER,
      },
      showValidation: false,
      updateInProgress: false,
    };
  },
  computed: {
    createProtectionRuleMutationInput() {
      return {
        projectPath: this.projectPath,
        tagNamePattern: this.protectionRuleFormData.tagNamePattern,
        minimumAccessLevelForPush: this.protectionRuleFormData.minimumAccessLevelForPush,
        minimumAccessLevelForDelete: this.protectionRuleFormData.minimumAccessLevelForDelete,
      };
    },
    isTagNamePatternValid() {
      if (this.showValidation) {
        return this.tagNamePattern.length > 0 && this.tagNamePattern.length < 100;
      }
      return true;
    },
    invalidFeedback() {
      if (this.tagNamePattern.length >= 100) {
        return s__('ContainerRegistry|Must be less than 100 characters.');
      }
      return s__('ContainerRegistry|This field is required.');
    },
    tagNamePattern() {
      return this.protectionRuleFormData.tagNamePattern;
    },
  },
  methods: {
    submit() {
      this.showValidation = true;

      if (!this.isTagNamePatternValid) return;

      this.clearAlertErrorMessages();
      this.updateInProgress = true;

      this.$apollo
        .mutate({
          mutation: createProtectionTagRuleMutation,
          variables: {
            input: this.createProtectionRuleMutationInput,
          },
        })
        .then(({ data }) => {
          const errorMessages = data?.createContainerProtectionTagRule?.errors ?? [];
          if (errorMessages?.length) {
            this.alertErrorMessages = Array.isArray(errorMessages)
              ? errorMessages
              : [errorMessages];
            return;
          }

          this.$emit('submit', data.createContainerProtectionTagRule.containerProtectionTagRule);
          this.trackEvent('container_protection_tag_rule_created');
        })
        .catch((error) => {
          this.handleError(error);
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
    handleError(error) {
      const errors = error?.graphQLErrors;

      if (errors?.length) {
        this.alertErrorMessages = errors.map((e) => e.message);
      } else {
        Sentry.captureException(error);
        this.alertErrorMessages = [
          s__('ContainerRegistry|Something went wrong while saving the protection rule.'),
        ];
      }
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
      :label="s__('ContainerRegistry|Protect container tags matching')"
      label-for="input-tag-name-pattern"
      :invalid-feedback="invalidFeedback"
      :state="isTagNamePatternValid"
    >
      <gl-form-input
        id="input-tag-name-pattern"
        v-model.trim="protectionRuleFormData.tagNamePattern"
        type="text"
        required
        trim
        :state="isTagNamePatternValid"
        @change="showValidation = true"
      />
      <template #description>
        <gl-sprintf
          :message="
            s__(
              'ContainerRegistry|Tags with names that match this regex pattern are protected. Must be less than 100 characters. %{linkStart}What regex patterns are supported?%{linkEnd}',
            )
          "
        >
          <template #link="{ content }">
            <gl-link
              href="https://docs.gitlab.com/ee/user/packages/container_registry/protected_container_tags.html#regex-pattern-examples"
              target="_blank"
              >{{ content }}</gl-link
            >
          </template>
        </gl-sprintf>
      </template>
    </gl-form-group>

    <gl-form-group
      :label="s__('ContainerRegistry|Minimum role allowed to push')"
      label-for="input-minimum-access-level-for-push"
    >
      <gl-form-select
        id="input-minimum-access-level-for-push"
        v-model="protectionRuleFormData.minimumAccessLevelForPush"
        :options="$options.minimumAccessLevelOptions"
      />
      <template #description>
        {{
          s__(
            'ContainerRegistry|Only users with at least this role can push tags with a name that matches the protection rule.',
          )
        }}
      </template>
    </gl-form-group>

    <gl-form-group
      :label="s__('ContainerRegistry|Minimum role allowed to delete')"
      label-for="input-minimum-access-level-for-delete"
    >
      <gl-form-select
        id="input-minimum-access-level-for-delete"
        v-model="protectionRuleFormData.minimumAccessLevelForDelete"
        :options="$options.minimumAccessLevelOptions"
      />
      <template #description>
        {{
          s__(
            'ContainerRegistry|Only users with at least this role can delete tags with a name that matches the protection rule.',
          )
        }}
      </template>
    </gl-form-group>

    <div class="gl-flex gl-justify-start gl-gap-3">
      <gl-button
        class="js-no-auto-disable"
        variant="confirm"
        type="submit"
        data-testid="add-rule-btn"
        :loading="updateInProgress"
        >{{ s__('ContainerRegistry|Add rule') }}</gl-button
      >
      <gl-button type="reset">{{ __('Cancel') }}</gl-button>
    </div>
  </gl-form>
</template>
