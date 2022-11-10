<script>
import {
  GlAlert,
  GlButton,
  GlCollapse,
  GlFormCheckbox,
  GlFormCombobox,
  GlFormGroup,
  GlFormSelect,
  GlFormInput,
  GlFormTextarea,
  GlIcon,
  GlLink,
  GlModal,
  GlSprintf,
} from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import { getCookie, setCookie } from '~/lib/utils/common_utils';
import { __ } from '~/locale';
import Tracking from '~/tracking';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { mapComputed } from '~/vuex_shared/bindings';
import {
  AWS_TOKEN_CONSTANTS,
  ADD_CI_VARIABLE_MODAL_ID,
  AWS_TIP_DISMISSED_COOKIE_NAME,
  AWS_TIP_MESSAGE,
  CONTAINS_VARIABLE_REFERENCE_MESSAGE,
  ENVIRONMENT_SCOPE_LINK_TITLE,
  EVENT_LABEL,
  EVENT_ACTION,
} from '../constants';
import LegacyCiEnvironmentsDropdown from './legacy_ci_environments_dropdown.vue';
import { awsTokens, awsTokenList } from './ci_variable_autocomplete_tokens';

const trackingMixin = Tracking.mixin({ label: EVENT_LABEL });

export default {
  modalId: ADD_CI_VARIABLE_MODAL_ID,
  tokens: awsTokens,
  tokenList: awsTokenList,
  awsTipMessage: AWS_TIP_MESSAGE,
  containsVariableReferenceMessage: CONTAINS_VARIABLE_REFERENCE_MESSAGE,
  environmentScopeLinkTitle: ENVIRONMENT_SCOPE_LINK_TITLE,
  components: {
    LegacyCiEnvironmentsDropdown,
    GlAlert,
    GlButton,
    GlCollapse,
    GlFormCheckbox,
    GlFormCombobox,
    GlFormGroup,
    GlFormSelect,
    GlFormInput,
    GlFormTextarea,
    GlIcon,
    GlLink,
    GlModal,
    GlSprintf,
  },
  mixins: [glFeatureFlagsMixin(), trackingMixin],
  data() {
    return {
      isTipDismissed: getCookie(AWS_TIP_DISMISSED_COOKIE_NAME) === 'true',
      validationErrorEventProperty: '',
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
      'containsVariableReferenceLink',
      'protectedEnvironmentVariablesLink',
      'maskedEnvironmentVariablesLink',
      'environmentScopeLink',
    ]),
    ...mapComputed(
      [
        { key: 'key', updateFn: 'updateVariableKey' },
        { key: 'secret_value', updateFn: 'updateVariableValue' },
        { key: 'variable_type', updateFn: 'updateVariableType' },
        { key: 'environment_scope', updateFn: 'setEnvironmentScope' },
        { key: 'protected_variable', updateFn: 'updateVariableProtected' },
        { key: 'masked', updateFn: 'updateVariableMasked' },
      ],
      false,
      'variable',
    ),
    isTipVisible() {
      return !this.isTipDismissed && AWS_TOKEN_CONSTANTS.includes(this.variable.key);
    },
    canSubmit() {
      return (
        this.variableValidationState &&
        this.variable.key !== '' &&
        this.variable.secret_value !== ''
      );
    },
    canMask() {
      const regex = RegExp(this.maskableRegex);
      return regex.test(this.variable.secret_value);
    },
    containsVariableReference() {
      const regex = /\$/;
      return regex.test(this.variable.secret_value);
    },
    displayMaskedError() {
      return !this.canMask && this.variable.masked;
    },
    maskedState() {
      if (this.displayMaskedError) {
        return false;
      }
      return true;
    },
    modalActionText() {
      return this.variableBeingEdited ? __('Update variable') : __('Add variable');
    },
    maskedFeedback() {
      return this.displayMaskedError ? __('This variable can not be masked.') : '';
    },
    tokenValidationFeedback() {
      const tokenSpecificFeedback = this.$options.tokens?.[this.variable.key]?.invalidMessage;
      if (!this.tokenValidationState && tokenSpecificFeedback) {
        return tokenSpecificFeedback;
      }
      return '';
    },
    tokenValidationState() {
      const validator = this.$options.tokens?.[this.variable.key]?.validation;

      if (validator) {
        return validator(this.variable.secret_value);
      }

      return true;
    },
    scopedVariablesAvailable() {
      return !this.isGroup || this.glFeatures.groupScopedCiVariables;
    },
    variableValidationFeedback() {
      return `${this.tokenValidationFeedback} ${this.maskedFeedback}`;
    },
    variableValidationState() {
      return this.variable.secret_value === '' || (this.tokenValidationState && this.maskedState);
    },
  },
  watch: {
    variable: {
      handler() {
        this.trackVariableValidationErrors();
      },
      deep: true,
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
      setCookie(AWS_TIP_DISMISSED_COOKIE_NAME, 'true', { expires: 90 });
      this.isTipDismissed = true;
    },
    deleteVarAndClose() {
      this.deleteVariable();
      this.hideModal();
    },
    hideModal() {
      this.$refs.modal.hide();
    },
    resetModalHandler() {
      if (this.variableBeingEdited) {
        this.resetEditing();
      }

      this.clearModal();
      this.resetSelectedEnvironment();
      this.resetValidationErrorEvents();
    },
    updateOrAddVariable() {
      if (this.variableBeingEdited) {
        this.updateVariable();
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
    trackVariableValidationErrors() {
      const property = this.getTrackingErrorProperty();
      if (!this.validationErrorEventProperty && property) {
        this.track(EVENT_ACTION, { property });
        this.validationErrorEventProperty = property;
      }
    },
    getTrackingErrorProperty() {
      let property;
      if (this.variable.secret_value?.length && !property) {
        if (this.displayMaskedError && this.maskableRegex?.length) {
          const supportedChars = this.maskableRegex.replace('^', '').replace(/{(\d,)}\$/, '');
          const regex = new RegExp(supportedChars, 'g');
          property = this.variable.secret_value.replace(regex, '');
        }
        if (this.containsVariableReference) {
          property = '$';
        }
      }

      return property;
    },
    resetValidationErrorEvents() {
      this.validationErrorEventProperty = '';
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
      <gl-form-combobox
        v-model="key"
        :token-list="$options.tokenList"
        :label-text="__('Key')"
        data-testid="pipeline-form-ci-variable-key"
        data-qa-selector="ci_variable_key_field"
      />

      <gl-form-group
        :label="__('Value')"
        label-for="ci-variable-value"
        :state="variableValidationState"
        :invalid-feedback="variableValidationFeedback"
      >
        <gl-form-textarea
          id="ci-variable-value"
          ref="valueField"
          v-model="secret_value"
          :state="variableValidationState"
          rows="3"
          max-rows="10"
          data-testid="pipeline-form-ci-variable-value"
          data-qa-selector="ci_variable_value_field"
          class="gl-font-monospace!"
        />
      </gl-form-group>

      <div class="d-flex">
        <gl-form-group :label="__('Type')" label-for="ci-variable-type" class="w-50 gl-mr-5">
          <gl-form-select id="ci-variable-type" v-model="variable_type" :options="typeOptions" />
        </gl-form-group>

        <gl-form-group label-for="ci-variable-env" class="w-50" data-testid="environment-scope">
          <template #label>
            {{ __('Environment scope') }}
            <gl-link
              :title="$options.environmentScopeLinkTitle"
              :href="environmentScopeLink"
              target="_blank"
              data-testid="environment-scope-link"
            >
              <gl-icon name="question" :size="12" />
            </gl-link>
          </template>
          <legacy-ci-environments-dropdown
            v-if="scopedVariablesAvailable"
            class="w-100"
            :value="environment_scope"
            @selectEnvironment="setEnvironmentScope"
            @createClicked="addWildCardScope"
          />

          <gl-form-input v-else v-model="environment_scope" class="w-100" readonly />
        </gl-form-group>
      </div>

      <gl-form-group :label="__('Flags')" label-for="ci-variable-flags">
        <gl-form-checkbox
          v-model="protected_variable"
          class="mb-0"
          data-testid="ci-variable-protected-checkbox"
        >
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
          v-model="masked"
          data-testid="ci-variable-masked-checkbox"
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
    <gl-alert
      v-if="containsVariableReference"
      :title="__('Value might contain a variable reference')"
      :dismissible="false"
      variant="warning"
      data-testid="contains-variable-reference"
    >
      <gl-sprintf :message="$options.containsVariableReferenceMessage">
        <template #code="{ content }">
          <code>{{ content }}</code>
        </template>
        <template #docsLink="{ content }">
          <gl-link :href="containsVariableReferenceLink" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </gl-alert>
    <template #modal-footer>
      <gl-button @click="hideModal">{{ __('Cancel') }}</gl-button>
      <gl-button
        v-if="variableBeingEdited"
        ref="deleteCiVariable"
        variant="danger"
        category="secondary"
        data-qa-selector="ci_variable_delete_button"
        @click="deleteVarAndClose"
        >{{ __('Delete variable') }}</gl-button
      >
      <gl-button
        ref="updateOrAddVariable"
        :disabled="!canSubmit"
        variant="confirm"
        category="primary"
        data-testid="ciUpdateOrAddVariableBtn"
        data-qa-selector="ci_variable_save_button"
        @click="updateOrAddVariable"
        >{{ modalActionText }}
      </gl-button>
    </template>
  </gl-modal>
</template>
