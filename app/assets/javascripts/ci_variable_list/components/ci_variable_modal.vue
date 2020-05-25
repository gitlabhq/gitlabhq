<script>
import {
  GlDeprecatedButton,
  GlModal,
  GlFormSelect,
  GlFormGroup,
  GlFormInput,
  GlFormTextarea,
  GlFormCheckbox,
  GlLink,
  GlIcon,
} from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import { __ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { ADD_CI_VARIABLE_MODAL_ID } from '../constants';
import { awsTokens, awsTokenList } from './ci_variable_autocomplete_tokens';
import CiKeyField from './ci_key_field.vue';
import CiEnvironmentsDropdown from './ci_environments_dropdown.vue';

export default {
  modalId: ADD_CI_VARIABLE_MODAL_ID,
  components: {
    CiEnvironmentsDropdown,
    CiKeyField,
    GlDeprecatedButton,
    GlModal,
    GlFormSelect,
    GlFormGroup,
    GlFormInput,
    GlFormTextarea,
    GlFormCheckbox,
    GlLink,
    GlIcon,
  },
  mixins: [glFeatureFlagsMixin()],
  tokens: awsTokens,
  tokenList: awsTokenList,
  computed: {
    ...mapState([
      'projectId',
      'environments',
      'typeOptions',
      'variable',
      'variableBeingEdited',
      'isGroup',
      'maskableRegex',
      'selectedEnvironment',
      'isProtectedByDefault',
    ]),
    canSubmit() {
      return (
        this.variableValidationState &&
        this.variableData.key !== '' &&
        this.variableData.secret_value !== ''
      );
    },
    canMask() {
      const regex = RegExp(this.maskableRegex);
      return regex.test(this.variableData.secret_value);
    },
    displayMaskedError() {
      return !this.canMask && this.variableData.masked;
    },
    maskedState() {
      if (this.displayMaskedError) {
        return false;
      }
      return true;
    },
    variableData() {
      return this.variableBeingEdited || this.variable;
    },
    modalActionText() {
      return this.variableBeingEdited ? __('Update variable') : __('Add variable');
    },
    maskedFeedback() {
      return this.displayMaskedError ? __('This variable can not be masked.') : '';
    },
    tokenValidationFeedback() {
      const tokenSpecificFeedback = this.$options.tokens?.[this.variableData.key]?.invalidMessage;
      if (!this.tokenValidationState && tokenSpecificFeedback) {
        return tokenSpecificFeedback;
      }
      return '';
    },
    tokenValidationState() {
      // If the feature flag is off, do not validate. Remove when flag is removed.
      if (!this.glFeatures.ciKeyAutocomplete) {
        return true;
      }

      const validator = this.$options.tokens?.[this.variableData.key]?.validation;

      if (validator) {
        return validator(this.variableData.secret_value);
      }

      return true;
    },
    variableValidationFeedback() {
      return `${this.tokenValidationFeedback} ${this.maskedFeedback}`;
    },
    variableValidationState() {
      if (
        this.variableData.secret_value === '' ||
        (this.tokenValidationState && this.maskedState)
      ) {
        return true;
      }

      return false;
    },
  },
  methods: {
    ...mapActions([
      'addVariable',
      'updateVariable',
      'resetEditing',
      'displayInputValue',
      'clearModal',
      'deleteVariable',
      'setEnvironmentScope',
      'addWildCardScope',
      'resetSelectedEnvironment',
      'setSelectedEnvironment',
      'setVariableProtected',
    ]),
    deleteVarAndClose() {
      this.deleteVariable(this.variableBeingEdited);
      this.hideModal();
    },
    hideModal() {
      this.$refs.modal.hide();
    },
    resetModalHandler() {
      if (this.variableBeingEdited) {
        this.resetEditing();
      } else {
        this.clearModal();
      }
      this.resetSelectedEnvironment();
    },
    updateOrAddVariable() {
      if (this.variableBeingEdited) {
        this.updateVariable(this.variableBeingEdited);
      } else {
        this.addVariable();
      }
      this.hideModal();
    },
    setVariableProtectedByDefault() {
      if (this.isProtectedByDefault && !this.variableBeingEdited) {
        this.setVariableProtected();
      }
    },
  },
};
</script>

<template>
  <gl-modal
    ref="modal"
    :modal-id="$options.modalId"
    :title="modalActionText"
    static
    lazy
    @hidden="resetModalHandler"
    @shown="setVariableProtectedByDefault"
  >
    <form>
      <ci-key-field
        v-if="glFeatures.ciKeyAutocomplete"
        v-model="variableData.key"
        :token-list="$options.tokenList"
      />

      <gl-form-group v-else :label="__('Key')" label-for="ci-variable-key">
        <gl-form-input
          id="ci-variable-key"
          v-model="variableData.key"
          data-qa-selector="ci_variable_key_field"
        />
      </gl-form-group>

      <gl-form-group
        :label="__('Value')"
        label-for="ci-variable-value"
        :state="variableValidationState"
        :invalid-feedback="variableValidationFeedback"
      >
        <gl-form-textarea
          id="ci-variable-value"
          ref="valueField"
          v-model="variableData.secret_value"
          :state="variableValidationState"
          rows="3"
          max-rows="6"
          data-qa-selector="ci_variable_value_field"
        />
      </gl-form-group>

      <div class="d-flex">
        <gl-form-group
          :label="__('Type')"
          label-for="ci-variable-type"
          class="w-50 append-right-15"
          :class="{ 'w-100': isGroup }"
        >
          <gl-form-select
            id="ci-variable-type"
            v-model="variableData.variable_type"
            :options="typeOptions"
          />
        </gl-form-group>

        <gl-form-group
          v-if="!isGroup"
          :label="__('Environment scope')"
          label-for="ci-variable-env"
          class="w-50"
        >
          <ci-environments-dropdown
            class="w-100"
            :value="variableData.environment_scope"
            @selectEnvironment="setEnvironmentScope"
            @createClicked="addWildCardScope"
          />
        </gl-form-group>
      </div>

      <gl-form-group :label="__('Flags')" label-for="ci-variable-flags">
        <gl-form-checkbox v-model="variableData.protected" class="mb-0">
          {{ __('Protect variable') }}
          <gl-link href="/help/ci/variables/README#protected-environment-variables">
            <gl-icon name="question" :size="12" />
          </gl-link>
          <p class="prepend-top-4 text-secondary">
            {{ __('Export variable to pipelines running on protected branches and tags only.') }}
          </p>
        </gl-form-checkbox>

        <gl-form-checkbox
          ref="masked-ci-variable"
          v-model="variableData.masked"
          data-qa-selector="ci_variable_masked_checkbox"
        >
          {{ __('Mask variable') }}
          <gl-link href="/help/ci/variables/README#masked-variables">
            <gl-icon name="question" :size="12" />
          </gl-link>
          <p class="prepend-top-4 gl-mb-0 text-secondary">
            {{ __('Variable will be masked in job logs.') }}
            <span
              :class="{
                'bold text-plain': displayMaskedError,
              }"
            >
              {{ __('Requires values to meet regular expression requirements.') }}</span
            >
            <gl-link href="/help/ci/variables/README#masked-variables">{{
              __('More information')
            }}</gl-link>
          </p>
        </gl-form-checkbox>
      </gl-form-group>
    </form>
    <template #modal-footer>
      <gl-deprecated-button @click="hideModal">{{ __('Cancel') }}</gl-deprecated-button>
      <gl-deprecated-button
        v-if="variableBeingEdited"
        ref="deleteCiVariable"
        category="secondary"
        variant="danger"
        data-qa-selector="ci_variable_delete_button"
        @click="deleteVarAndClose"
        >{{ __('Delete variable') }}</gl-deprecated-button
      >
      <gl-deprecated-button
        ref="updateOrAddVariable"
        :disabled="!canSubmit"
        variant="success"
        data-qa-selector="ci_variable_save_button"
        @click="updateOrAddVariable"
        >{{ modalActionText }}
      </gl-deprecated-button>
    </template>
  </gl-modal>
</template>
