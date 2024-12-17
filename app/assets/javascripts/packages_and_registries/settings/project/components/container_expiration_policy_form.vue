<script>
import { GlButton, GlSprintf } from '@gitlab/ui';
import { objectToQuery, visitUrl } from '~/lib/utils/url_utility';
import {
  UPDATE_SETTINGS_ERROR_MESSAGE,
  SHOW_SETUP_SUCCESS_ALERT,
  SET_CLEANUP_POLICY_BUTTON,
  KEEP_HEADER_TEXT,
  KEEP_INFO_TEXT,
  KEEP_N_LABEL,
  NAME_REGEX_KEEP_LABEL,
  NAME_REGEX_KEEP_DESCRIPTION,
  REMOVE_HEADER_TEXT,
  REMOVE_INFO_TEXT,
  EXPIRATION_SCHEDULE_LABEL,
  NAME_REGEX_LABEL,
  NAME_REGEX_DESCRIPTION,
  CADENCE_LABEL,
  EXPIRATION_POLICY_FOOTER_NOTE,
} from '~/packages_and_registries/settings/project/constants';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import updateContainerExpirationPolicyMutation from '~/packages_and_registries/settings/project/graphql/mutations/update_container_expiration_policy.mutation.graphql';
import { updateContainerExpirationPolicy } from '~/packages_and_registries/settings/project/graphql/utils/cache_update';
import { formOptionsGenerator } from '~/packages_and_registries/settings/project/utils';
import Tracking from '~/tracking';
import ExpirationDropdown from './expiration_dropdown.vue';
import ExpirationInput from './expiration_input.vue';
import ExpirationRunText from './expiration_run_text.vue';
import ExpirationToggle from './expiration_toggle.vue';

export default {
  components: {
    GlButton,
    GlSprintf,
    ExpirationDropdown,
    ExpirationInput,
    ExpirationToggle,
    ExpirationRunText,
    CrudComponent,
  },
  mixins: [Tracking.mixin()],
  inject: ['projectPath', 'projectSettingsPath'],
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
    isEdited: {
      type: Boolean,
      required: false,
      default: false,
    },
  },

  formOptions: formOptionsGenerator(),
  i18n: {
    KEEP_HEADER_TEXT,
    KEEP_INFO_TEXT,
    KEEP_N_LABEL,
    NAME_REGEX_KEEP_LABEL,
    SET_CLEANUP_POLICY_BUTTON,
    NAME_REGEX_KEEP_DESCRIPTION,
    REMOVE_HEADER_TEXT,
    REMOVE_INFO_TEXT,
    EXPIRATION_SCHEDULE_LABEL,
    NAME_REGEX_LABEL,
    NAME_REGEX_DESCRIPTION,
    CADENCE_LABEL,
    EXPIRATION_POLICY_FOOTER_NOTE,
  },
  data() {
    return {
      tracking: {
        label: 'docker_container_retention_and_expiration_policies',
      },
      apiErrors: {},
      localErrors: {},
      mutationLoading: false,
    };
  },
  computed: {
    prefilledForm() {
      return {
        ...this.value,
        cadence: this.findDefaultOption('cadence'),
      };
    },
    showLoadingIcon() {
      return this.isLoading || this.mutationLoading;
    },
    fieldsAreValid() {
      return Object.values(this.localErrors).every((error) => error);
    },
    isSubmitButtonDisabled() {
      return !this.isEdited || !this.fieldsAreValid || this.showLoadingIcon;
    },
    isCancelButtonDisabled() {
      return this.isLoading || this.mutationLoading;
    },
    isFieldDisabled() {
      return this.showLoadingIcon || !this.value.enabled;
    },
    mutationVariables() {
      return {
        projectPath: this.projectPath,
        enabled: this.prefilledForm.enabled,
        cadence: this.prefilledForm.cadence,
        olderThan: this.prefilledForm.olderThan,
        keepN: this.prefilledForm.keepN,
        nameRegex: this.prefilledForm.nameRegex,
        nameRegexKeep: this.prefilledForm.nameRegexKeep,
      };
    },
  },
  methods: {
    findDefaultOption(option) {
      return this.value[option] || this.$options.formOptions[option].find((f) => f.default)?.key;
    },
    setApiErrors(response) {
      this.apiErrors = response.graphQLErrors.reduce((acc, curr) => {
        curr.extensions.problems.forEach((item) => {
          acc[item.path[0]] = item.message;
        });
        return acc;
      }, {});
    },
    setLocalErrors(state, model) {
      this.localErrors = {
        ...this.localErrors,
        [model]: state,
      };
    },
    encapsulateError(path, message) {
      return {
        graphQLErrors: [
          {
            extensions: {
              problems: [{ path: [path], message }],
            },
          },
        ],
      };
    },
    submit() {
      this.track('submit_form');
      this.apiErrors = {};
      this.mutationLoading = true;
      return this.$apollo
        .mutate({
          mutation: updateContainerExpirationPolicyMutation,
          variables: {
            input: this.mutationVariables,
          },
          update: updateContainerExpirationPolicy(this.projectPath),
        })
        .then(({ data }) => {
          const errorMessage = data?.updateContainerExpirationPolicy?.errors[0];
          if (errorMessage) {
            const customError = this.encapsulateError('nameRegex', errorMessage);
            throw customError;
          } else {
            this.navigateToSettingsWithSuccessAlert();
          }
        })
        .catch((error) => {
          this.setApiErrors(error);
          this.$toast.show(UPDATE_SETTINGS_ERROR_MESSAGE);
        })
        .finally(() => {
          this.mutationLoading = false;
        });
    },
    onModelChange(newValue, model) {
      this.$emit('input', { ...this.value, [model]: newValue });
      this.apiErrors[model] = undefined;
    },
    navigateToSettingsWithSuccessAlert() {
      const alertQuery = objectToQuery({ [SHOW_SETUP_SUCCESS_ALERT]: true });

      visitUrl(`${this.projectSettingsPath}?${alertQuery}`);
    },
  },
};
</script>

<template>
  <form @submit.prevent="submit">
    <expiration-toggle
      :value="prefilledForm.enabled"
      :disabled="showLoadingIcon"
      class="!gl-mb-0"
      data-testid="enable-toggle"
      @input="onModelChange($event, 'enabled')"
    />

    <div class="gl-mt-5 gl-flex">
      <expiration-dropdown
        :value="prefilledForm.cadence"
        :disabled="isFieldDisabled"
        :form-options="$options.formOptions.cadence"
        :label="$options.i18n.CADENCE_LABEL"
        name="cadence"
        class="!gl-mb-0 gl-mr-7"
        data-testid="cadence-dropdown"
        @input="onModelChange($event, 'cadence')"
      />
      <expiration-run-text
        :value="prefilledForm.nextRunAt"
        :enabled="prefilledForm.enabled"
        class="!gl-mb-0"
      />
    </div>
    <crud-component :title="$options.i18n.KEEP_HEADER_TEXT" class="gl-mt-5">
      <p>
        <gl-sprintf :message="$options.i18n.KEEP_INFO_TEXT">
          <template #strong="{ content }">
            <strong>{{ content }}</strong>
          </template>
        </gl-sprintf>
      </p>
      <expiration-dropdown
        :value="prefilledForm.keepN"
        :disabled="isFieldDisabled"
        :form-options="$options.formOptions.keepN"
        :label="$options.i18n.KEEP_N_LABEL"
        name="keep-n"
        data-testid="keep-n-dropdown"
        @input="onModelChange($event, 'keepN')"
      />
      <expiration-input
        v-model="prefilledForm.nameRegexKeep"
        :error="apiErrors.nameRegexKeep"
        :disabled="isFieldDisabled"
        :label="$options.i18n.NAME_REGEX_KEEP_LABEL"
        :description="$options.i18n.NAME_REGEX_KEEP_DESCRIPTION"
        name="keep-regex"
        data-testid="keep-regex-input"
        @input="onModelChange($event, 'nameRegexKeep')"
        @validation="setLocalErrors($event, 'nameRegexKeep')"
      />
    </crud-component>
    <crud-component :title="$options.i18n.REMOVE_HEADER_TEXT" class="gl-mt-5">
      <div>
        <p>
          <gl-sprintf :message="$options.i18n.REMOVE_INFO_TEXT">
            <template #strong="{ content }">
              <strong>{{ content }}</strong>
            </template>
          </gl-sprintf>
        </p>
        <expiration-dropdown
          :value="prefilledForm.olderThan"
          :disabled="isFieldDisabled"
          :form-options="$options.formOptions.olderThan"
          :label="$options.i18n.EXPIRATION_SCHEDULE_LABEL"
          name="older-than"
          data-testid="older-than-dropdown"
          @input="onModelChange($event, 'olderThan')"
        />
        <expiration-input
          v-model="prefilledForm.nameRegex"
          :error="apiErrors.nameRegex"
          :disabled="isFieldDisabled"
          :label="$options.i18n.NAME_REGEX_LABEL"
          :description="$options.i18n.NAME_REGEX_DESCRIPTION"
          name="remove-regex"
          data-testid="remove-regex-input"
          @input="onModelChange($event, 'nameRegex')"
          @validation="setLocalErrors($event, 'nameRegex')"
        />
      </div>
    </crud-component>
    <div class="settings-sticky-footer gl-mt-5 gl-flex gl-items-center">
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
      <gl-button
        data-testid="cancel-button"
        :href="projectSettingsPath"
        :disabled="isCancelButtonDisabled"
        class="gl-mr-4"
      >
        {{ __('Cancel') }}
      </gl-button>
      <span class="gl-italic gl-text-subtle">{{
        $options.i18n.EXPIRATION_POLICY_FOOTER_NOTE
      }}</span>
    </div>
  </form>
</template>
