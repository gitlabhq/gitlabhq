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
import { helpPagePath } from '~/helpers/help_page_helper';
import { getCookie, setCookie } from '~/lib/utils/common_utils';
import { __ } from '~/locale';
import Tracking from '~/tracking';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

import {
  allEnvironments,
  AWS_TOKEN_CONSTANTS,
  ADD_CI_VARIABLE_MODAL_ID,
  AWS_TIP_DISMISSED_COOKIE_NAME,
  AWS_TIP_MESSAGE,
  CONTAINS_VARIABLE_REFERENCE_MESSAGE,
  defaultVariableState,
  ENVIRONMENT_SCOPE_LINK_TITLE,
  EVENT_LABEL,
  EVENT_ACTION,
  EXPANDED_VARIABLES_NOTE,
  EDIT_VARIABLE_ACTION,
  FLAG_LINK_TITLE,
  VARIABLE_ACTIONS,
  variableOptions,
} from '../constants';
import { createJoinedEnvironments } from '../utils';
import CiEnvironmentsDropdown from './ci_environments_dropdown.vue';
import { awsTokens, awsTokenList } from './ci_variable_autocomplete_tokens';

const trackingMixin = Tracking.mixin({ label: EVENT_LABEL });

export default {
  components: {
    CiEnvironmentsDropdown,
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
  inject: [
    'awsLogoSvgPath',
    'awsTipCommandsLink',
    'awsTipDeployLink',
    'awsTipLearnLink',
    'containsVariableReferenceLink',
    'environmentScopeLink',
    'isProtectedByDefault',
    'maskedEnvironmentVariablesLink',
    'maskableRawRegex',
    'maskableRegex',
  ],
  props: {
    areEnvironmentsLoading: {
      type: Boolean,
      required: true,
    },
    areScopedVariablesAvailable: {
      type: Boolean,
      required: false,
      default: false,
    },
    environments: {
      type: Array,
      required: false,
      default: () => [],
    },
    hideEnvironmentScope: {
      type: Boolean,
      required: false,
      default: false,
    },
    mode: {
      type: String,
      required: true,
      validator(val) {
        return VARIABLE_ACTIONS.includes(val);
      },
    },
    selectedVariable: {
      type: Object,
      required: false,
      default: () => {},
    },
    variables: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      newEnvironments: [],
      isTipDismissed: getCookie(AWS_TIP_DISMISSED_COOKIE_NAME) === 'true',
      validationErrorEventProperty: '',
      variable: { ...defaultVariableState, ...this.selectedVariable },
    };
  },
  computed: {
    canMask() {
      const regex = RegExp(this.useRawMaskableRegexp ? this.maskableRawRegex : this.maskableRegex);
      return regex.test(this.variable.value);
    },
    canSubmit() {
      return this.variableValidationState && this.variable.key !== '' && this.variable.value !== '';
    },
    containsVariableReference() {
      const regex = /\$/;
      return regex.test(this.variable.value) && this.isExpanded;
    },
    displayMaskedError() {
      return !this.canMask && this.variable.masked;
    },
    isEditing() {
      return this.mode === EDIT_VARIABLE_ACTION;
    },
    isExpanded() {
      return !this.isRaw;
    },
    isRaw() {
      return this.variable.raw;
    },
    isTipVisible() {
      return !this.isTipDismissed && AWS_TOKEN_CONSTANTS.includes(this.variable.key);
    },
    environmentsList() {
      if (this.glFeatures?.ciLimitEnvironmentScope) {
        return this.environments;
      }

      return createJoinedEnvironments(this.variables, this.environments, this.newEnvironments);
    },
    maskedFeedback() {
      return this.displayMaskedError ? __('This variable can not be masked.') : '';
    },
    maskedState() {
      if (this.displayMaskedError) {
        return false;
      }
      return true;
    },
    modalActionText() {
      return this.isEditing ? __('Update variable') : __('Add variable');
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
        return validator(this.variable.value);
      }

      return true;
    },
    useRawMaskableRegexp() {
      return this.isRaw;
    },
    variableValidationFeedback() {
      return `${this.tokenValidationFeedback} ${this.maskedFeedback}`;
    },
    variableValidationState() {
      return this.variable.value === '' || (this.tokenValidationState && this.maskedState);
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
    addVariable() {
      this.$emit('add-variable', this.variable);
    },
    createEnvironmentScope(env) {
      this.newEnvironments.push(env);
    },
    deleteVariable() {
      this.$emit('delete-variable', this.variable);
    },
    updateVariable() {
      this.$emit('update-variable', this.variable);
    },
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
    onShow() {
      this.setVariableProtectedByDefault();
    },
    resetModalHandler() {
      this.resetVariableData();
      this.resetValidationErrorEvents();

      this.$emit('hideModal');
    },
    resetVariableData() {
      this.variable = { ...defaultVariableState };
    },
    setEnvironmentScope(scope) {
      this.variable = { ...this.variable, environmentScope: scope };
    },
    setVariableRaw(expanded) {
      this.variable = { ...this.variable, raw: !expanded };
    },
    setVariableProtected() {
      this.variable = { ...this.variable, protected: true };
    },
    updateOrAddVariable() {
      if (this.isEditing) {
        this.updateVariable();
      } else {
        this.addVariable();
      }
      this.hideModal();
    },
    setVariableProtectedByDefault() {
      if (this.isProtectedByDefault && !this.isEditing) {
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
      if (this.variable.value?.length && !property) {
        if (this.displayMaskedError && this.maskableRegex?.length) {
          const supportedChars = this.maskableRegex.replace('^', '').replace(/{(\d,)}\$/, '');
          const regex = new RegExp(supportedChars, 'g');
          property = this.variable.value.replace(regex, '');
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
  i18n: {
    awsTipMessage: AWS_TIP_MESSAGE,
    containsVariableReferenceMessage: CONTAINS_VARIABLE_REFERENCE_MESSAGE,
    defaultScope: allEnvironments.text,
    environmentScopeLinkTitle: ENVIRONMENT_SCOPE_LINK_TITLE,
    expandedVariablesNote: EXPANDED_VARIABLES_NOTE,
    flagsLinkTitle: FLAG_LINK_TITLE,
  },
  flagLink: helpPagePath('ci/variables/index', {
    anchor: 'define-a-cicd-variable-in-the-ui',
  }),
  modalId: ADD_CI_VARIABLE_MODAL_ID,
  tokens: awsTokens,
  tokenList: awsTokenList,
  variableOptions,
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
    @shown="onShow"
  >
    <form>
      <gl-form-combobox
        v-model="variable.key"
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
          v-model="variable.value"
          :state="variableValidationState"
          rows="3"
          max-rows="10"
          data-testid="pipeline-form-ci-variable-value"
          data-qa-selector="ci_variable_value_field"
          class="gl-font-monospace!"
          spellcheck="false"
        />
        <p v-if="isRaw" class="gl-mt-2 gl-mb-0 text-secondary" data-testid="raw-variable-tip">
          {{ __('Variable value will be evaluated as raw string.') }}
        </p>
      </gl-form-group>

      <div class="gl-display-flex">
        <gl-form-group :label="__('Type')" label-for="ci-variable-type" class="gl-w-half gl-mr-5">
          <gl-form-select
            id="ci-variable-type"
            v-model="variable.variableType"
            :options="$options.variableOptions"
          />
        </gl-form-group>

        <template v-if="!hideEnvironmentScope">
          <gl-form-group
            label-for="ci-variable-env"
            class="gl-w-half"
            data-testid="environment-scope"
          >
            <template #label>
              <div class="gl-display-flex gl-align-items-center">
                <span class="gl-mr-2">
                  {{ __('Environment scope') }}
                </span>
                <gl-link
                  class="gl-display-flex"
                  :title="$options.i18n.environmentScopeLinkTitle"
                  :href="environmentScopeLink"
                  target="_blank"
                  data-testid="environment-scope-link"
                >
                  <gl-icon name="question-o" :size="14" />
                </gl-link>
              </div>
            </template>
            <ci-environments-dropdown
              v-if="areScopedVariablesAvailable"
              :are-environments-loading="areEnvironmentsLoading"
              :selected-environment-scope="variable.environmentScope"
              :environments="environmentsList"
              @select-environment="setEnvironmentScope"
              @create-environment-scope="createEnvironmentScope"
              @search-environment-scope="$emit('search-environment-scope', $event)"
            />

            <gl-form-input v-else :value="$options.i18n.defaultScope" class="gl-w-full" readonly />
          </gl-form-group>
        </template>
      </div>

      <gl-form-group>
        <template #label>
          <div class="gl-display-flex gl-align-items-center">
            <span class="gl-mr-2">
              {{ __('Flags') }}
            </span>
            <gl-link
              class="gl-display-flex"
              :title="$options.i18n.flagsLinkTitle"
              :href="$options.flagLink"
              target="_blank"
            >
              <gl-icon name="question-o" :size="14" />
            </gl-link>
          </div>
        </template>
        <gl-form-checkbox
          v-model="variable.protected"
          class="gl-mb-0"
          data-testid="ci-variable-protected-checkbox"
          :data-is-protected-checked="variable.protected"
        >
          {{ __('Protect variable') }}
          <p class="gl-mt-2 text-secondary">
            {{ __('Export variable to pipelines running on protected branches and tags only.') }}
          </p>
        </gl-form-checkbox>
        <gl-form-checkbox
          ref="masked-ci-variable"
          v-model="variable.masked"
          data-testid="ci-variable-masked-checkbox"
        >
          {{ __('Mask variable') }}
          <p class="gl-mt-2 text-secondary">
            {{ __('Variable will be masked in job logs.') }}
            <span
              :class="{
                'bold text-plain': displayMaskedError,
              }"
            >
              {{ __('Requires values to meet regular expression requirements.') }}</span
            >
            <gl-link target="_blank" :href="maskedEnvironmentVariablesLink">{{
              __('Learn more.')
            }}</gl-link>
          </p>
        </gl-form-checkbox>
        <gl-form-checkbox
          ref="expanded-ci-variable"
          :checked="isExpanded"
          data-testid="ci-variable-expanded-checkbox"
          @change="setVariableRaw"
        >
          {{ __('Expand variable reference') }}
          <p class="gl-mt-2 gl-mb-0 gl-text-secondary">
            <gl-sprintf :message="$options.i18n.expandedVariablesNote">
              <template #code="{ content }">
                <code>{{ content }}</code>
              </template>
            </gl-sprintf>
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
        <div class="gl-display-flex gl-flex-direction-row gl-flex-wrap gl-md-flex-nowrap gl-gap-3">
          <div>
            <p>
              <gl-sprintf :message="$options.i18n.awsTipMessage">
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
                variant="confirm"
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
      <gl-sprintf :message="$options.i18n.containsVariableReferenceMessage">
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
        v-if="isEditing"
        ref="deleteCiVariable"
        variant="danger"
        category="secondary"
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
