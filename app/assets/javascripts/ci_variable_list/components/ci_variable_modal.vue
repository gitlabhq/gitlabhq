<script>
import {
  GlAlert,
  GlButton,
  GlCollapse,
  GlDeprecatedButton,
  GlFormCheckbox,
  GlFormGroup,
  GlFormInput,
  GlFormSelect,
  GlFormTextarea,
  GlIcon,
  GlLink,
  GlModal,
  GlSprintf,
} from '@gitlab/ui';
import Cookies from 'js-cookie';
import { mapActions, mapState } from 'vuex';
import { __ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import {
  AWS_TOKEN_CONSTANTS,
  ADD_CI_VARIABLE_MODAL_ID,
  AWS_TIP_DISMISSED_COOKIE_NAME,
  AWS_TIP_MESSAGE,
} from '../constants';
import { awsTokens, awsTokenList } from './ci_variable_autocomplete_tokens';
import CiKeyField from './ci_key_field.vue';
import CiEnvironmentsDropdown from './ci_environments_dropdown.vue';

export default {
  modalId: ADD_CI_VARIABLE_MODAL_ID,
  components: {
    CiEnvironmentsDropdown,
    CiKeyField,
    GlAlert,
    GlButton,
    GlCollapse,
    GlDeprecatedButton,
    GlFormCheckbox,
    GlFormGroup,
    GlFormInput,
    GlFormSelect,
    GlFormTextarea,
    GlIcon,
    GlLink,
    GlModal,
    GlSprintf,
  },
  mixins: [glFeatureFlagsMixin()],
  tokens: awsTokens,
  tokenList: awsTokenList,
  awsTipMessage: AWS_TIP_MESSAGE,
  data() {
    return {
      isTipDismissed: Cookies.get(AWS_TIP_DISMISSED_COOKIE_NAME) === 'true',
    };
  },
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
      'awsLogoSvgPath',
      'awsTipDeployLink',
      'awsTipCommandsLink',
      'awsTipLearnLink',
      'protectedEnvironmentVariablesLink',
      'maskedEnvironmentVariablesLink',
    ]),
    isTipVisible() {
      return !this.isTipDismissed && AWS_TOKEN_CONSTANTS.includes(this.variableData.key);
    },
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
    dismissTip() {
      Cookies.set(AWS_TIP_DISMISSED_COOKIE_NAME, 'true', { expires: 90 });
      this.isTipDismissed = true;
    },
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
          <gl-link target="_blank" :href="protectedEnvironmentVariablesLink">
            <gl-icon name="question" :size="12" />
          </gl-link>
          <p class="gl-mt-2 text-secondary">
            {{ __('Export variable to pipelines running on protected branches and tags only.') }}
          </p>
        </gl-form-checkbox>

        <gl-form-checkbox
          ref="masked-ci-variable"
          v-model="variableData.masked"
          data-qa-selector="ci_variable_masked_checkbox"
        >
          {{ __('Mask variable') }}
          <gl-link target="_blank" :href="maskedEnvironmentVariablesLink">
            <gl-icon name="question" :size="12" />
          </gl-link>
          <p class="gl-mt-2 gl-mb-0 text-secondary">
            {{ __('Variable will be masked in job logs.') }}
            <span
              :class="{
                'bold text-plain': displayMaskedError,
              }"
            >
              {{ __('Requires values to meet regular expression requirements.') }}</span
            >
            <gl-link target="_blank" :href="maskedEnvironmentVariablesLink">{{
              __('More information')
            }}</gl-link>
          </p>
        </gl-form-checkbox>
      </gl-form-group>
    </form>
    <gl-collapse :visible="isTipVisible">
      <gl-alert
        :title="__('Deploying to AWS is easy with GitLab')"
        variant="tip"
        data-testid="aws-guidance-tip"
        @dismiss="dismissTip"
      >
        <div class="gl-display-flex gl-flex-direction-row">
          <div>
            <p>
              <gl-sprintf :message="$options.awsTipMessage">
                <template #deployLink="{ content }">
                  <gl-link :href="awsTipDeployLink" target="_blank">{{ content }}</gl-link>
                </template>
                <template #commandsLink="{ content }">
                  <gl-link :href="awsTipCommandsLink" target="_blank">{{ content }}</gl-link>
                </template>
              </gl-sprintf>
            </p>
            <p>
              <gl-button
                :href="awsTipLearnLink"
                target="_blank"
                category="secondary"
                variant="info"
                class="gl-overflow-wrap-break"
                >{{ __('Learn more about deploying to AWS') }}</gl-button
              >
            </p>
          </div>
          <img
            class="gl-mt-3"
            :alt="__('Amazon Web Services Logo')"
            :src="awsLogoSvgPath"
            height="32"
          />
        </div>
      </gl-alert>
    </gl-collapse>
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
