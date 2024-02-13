<script>
import { isEqual } from 'lodash';
import {
  GlAlert,
  GlButton,
  GlDrawer,
  GlFormCheckbox,
  GlFormCombobox,
  GlFormGroup,
  GlFormInput,
  GlFormSelect,
  GlFormTextarea,
  GlIcon,
  GlLink,
  GlModal,
  GlModalDirective,
  GlSprintf,
} from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { helpPagePath } from '~/helpers/help_page_helper';
import Tracking from '~/tracking';
import CiEnvironmentsDropdown from '~/ci/common/private/ci_environments_dropdown';
import {
  defaultVariableState,
  ADD_VARIABLE_ACTION,
  DRAWER_EVENT_LABEL,
  EDIT_VARIABLE_ACTION,
  ENVIRONMENT_SCOPE_LINK_TITLE,
  EVENT_ACTION,
  EXPANDED_VARIABLES_NOTE,
  FLAG_LINK_TITLE,
  MASKED_VALUE_MIN_LENGTH,
  VARIABLE_ACTIONS,
  variableOptions,
  WHITESPACE_REG_EX,
} from '../constants';
import { awsTokenList } from './ci_variable_autocomplete_tokens';

const trackingMixin = Tracking.mixin({ label: DRAWER_EVENT_LABEL });
const KEY_REGEX = /^\w+$/;

export const i18n = {
  addVariable: s__('CiVariables|Add variable'),
  cancel: __('Cancel'),
  defaultScope: __('All (default)'),
  deleteVariable: s__('CiVariables|Delete variable'),
  description: __('Description'),
  descriptionHelpText: s__("CiVariables|The description of the variable's value or usage."),
  editVariable: s__('CiVariables|Edit variable'),
  saveVariable: __('Save changes'),
  environments: __('Environments'),
  environmentScopeLinkTitle: ENVIRONMENT_SCOPE_LINK_TITLE,
  expandedField: s__('CiVariables|Expand variable reference'),
  expandedDescription: EXPANDED_VARIABLES_NOTE,
  flags: __('Flags'),
  flagsLinkTitle: FLAG_LINK_TITLE,
  key: __('Key'),
  keyFeedback: s__("CiVariables|A variable key can only contain letters, numbers, and '_'."),
  keyHelpText: s__(
    'CiVariables|You can use CI/CD variables with the same name in different places, but the variables might overwrite each other. %{linkStart}What is the order of precedence for variables?%{linkEnd}',
  ),
  maskedField: s__('CiVariables|Mask variable'),
  maskedDescription: s__(
    'CiVariables|Variable will be masked in job logs. Requires values to meet regular expression requirements.',
  ),
  maskedValueMinLengthValidationText: s__(
    'CiVariables|The value must have at least %{charsAmount} characters.',
  ),
  modalDeleteMessage: s__('CiVariables|Do you want to delete the variable %{key}?'),
  protectedField: s__('CiVariables|Protect variable'),
  protectedDescription: s__(
    'CiVariables|Export variable to pipelines running on protected branches and tags only.',
  ),
  unsupportedCharsValidationText: s__(
    'CiVariables|This value cannot be masked because it contains the following characters: %{unsupportedChars}.',
  ),
  unsupportedAndWhitespaceCharsValidationText: s__(
    'CiVariables|This value cannot be masked because it contains the following characters: %{unsupportedChars} and whitespace characters.',
  ),
  valueFeedback: {
    rawHelpText: s__('CiVariables|Variable value will be evaluated as raw string.'),
  },
  variableReferenceTitle: s__('CiVariables|Value might contain a variable reference'),
  variableReferenceDescription: s__(
    'CiVariables|Unselect "Expand variable reference" if you want to use the variable value as a raw string.',
  ),
  whitespaceCharsValidationText: s__(
    'CiVariables|This value cannot be masked because it contains the following characters: whitespace characters.',
  ),
  type: __('Type'),
  value: __('Value'),
};

const VARIABLE_REFERENCE_REGEX = /\$/;

export default {
  DRAWER_Z_INDEX,
  components: {
    CiEnvironmentsDropdown,
    GlAlert,
    GlButton,
    GlDrawer,
    GlFormCheckbox,
    GlFormCombobox,
    GlFormGroup,
    GlFormInput,
    GlFormSelect,
    GlFormTextarea,
    GlIcon,
    GlLink,
    GlModal,
    GlSprintf,
  },
  directives: {
    GlModalDirective,
  },
  mixins: [trackingMixin],
  inject: ['environmentScopeLink', 'isProtectedByDefault', 'maskableRawRegex', 'maskableRegex'],
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
    mutationResponse: {
      type: Object,
      required: false,
      default: null,
    },
    selectedVariable: {
      type: Object,
      required: false,
      default: () => {},
    },
  },
  data() {
    return {
      isMutationAlertVisible: false,
      variable: { ...defaultVariableState, ...this.selectedVariable },
      trackedValidationErrorProperty: undefined,
    };
  },
  computed: {
    isValueMaskable() {
      return this.variable.masked && !this.isValueMasked;
    },
    isValueMasked() {
      const regex = RegExp(this.maskedRegexToUse);
      return regex.test(this.variable.value);
    },
    canSubmit() {
      return this.variable.key.length > 0 && this.isKeyValid && this.isValueValid;
    },
    getDrawerHeaderHeight() {
      return getContentWrapperHeight();
    },
    hasVariableReference() {
      return this.isExpanded && VARIABLE_REFERENCE_REGEX.test(this.variable.value);
    },
    isExpanded() {
      return !this.variable.raw;
    },
    isKeyValid() {
      return KEY_REGEX.test(this.variable.key);
    },
    isMaskedReqsMet() {
      return !this.variable.masked || this.isValueMasked;
    },
    isValueEmpty() {
      return this.variable.value === '';
    },
    isValueValid() {
      return this.isValueEmpty || this.isMaskedReqsMet;
    },
    isEditing() {
      return this.mode === EDIT_VARIABLE_ACTION;
    },
    isMaskedValueContainsWhitespaceChars() {
      return this.isValueMaskable && WHITESPACE_REG_EX.test(this.variable.value);
    },
    maskedRegexToUse() {
      return this.variable.raw ? this.maskableRawRegex : this.maskableRegex;
    },
    maskedSupportedCharsRegEx() {
      const supportedChars = this.maskedRegexToUse.replace('^', '').replace(/{(\d,)}\$/, '');
      return new RegExp(supportedChars, 'g');
    },
    maskedValueMinLengthValidationText() {
      return sprintf(this.$options.i18n.maskedValueMinLengthValidationText, {
        charsAmount: MASKED_VALUE_MIN_LENGTH,
      });
    },
    mutationAlertVariant() {
      if (this.mutationResponse.hasError) {
        return 'danger';
      }

      return 'success';
    },
    unsupportedCharsList() {
      if (this.isMaskedReqsMet) {
        return [];
      }

      return [
        ...new Set(
          this.variable.value
            .replace(WHITESPACE_REG_EX, '')
            .replace(this.maskedSupportedCharsRegEx, '')
            .split(''),
        ),
      ];
    },
    unsupportedChars() {
      return this.unsupportedCharsList.join(', ');
    },
    unsupportedCharsValidationText() {
      return sprintf(
        this.$options.i18n.unsupportedCharsValidationText,
        {
          unsupportedChars: this.unsupportedChars,
        },
        false,
      );
    },
    unsupportedAndWhitespaceCharsValidationText() {
      return sprintf(
        this.$options.i18n.unsupportedAndWhitespaceCharsValidationText,
        {
          unsupportedChars: this.unsupportedChars,
        },
        false,
      );
    },
    maskedValidationIssuesText() {
      if (this.isMaskedReqsMet) {
        return '';
      }

      let validationIssuesText = '';

      if (this.unsupportedCharsList.length && !this.isMaskedValueContainsWhitespaceChars) {
        validationIssuesText = this.unsupportedCharsValidationText;
      } else if (this.unsupportedCharsList.length && this.isMaskedValueContainsWhitespaceChars) {
        validationIssuesText = this.unsupportedAndWhitespaceCharsValidationText;
      } else if (!this.unsupportedCharsList.length && this.isMaskedValueContainsWhitespaceChars) {
        validationIssuesText = this.$options.i18n.whitespaceCharsValidationText;
      }

      if (this.variable.value.length < MASKED_VALUE_MIN_LENGTH) {
        validationIssuesText += ` ${this.maskedValueMinLengthValidationText}`;
      }

      return validationIssuesText.trim();
    },
    modalTitle() {
      return this.isEditing ? this.$options.i18n.editVariable : this.$options.i18n.addVariable;
    },
    modalActionText() {
      return this.isEditing ? this.$options.i18n.saveVariable : this.$options.i18n.addVariable;
    },
    removeVariableMessage() {
      return sprintf(this.$options.i18n.modalDeleteMessage, { key: this.variable.key });
    },
  },
  watch: {
    mutationResponse: {
      handler(response) {
        this.showMutationAlert();

        if (!response.hasError && this.mode === ADD_VARIABLE_ACTION) {
          this.resetForm();
        }
      },
    },
    variable: {
      handler(variable) {
        this.trackVariableValidationErrors();

        if (this.isMutationAlertVisible && !isEqual(variable, { ...defaultVariableState })) {
          this.hideMutationAlert();
        }
      },
      deep: true,
    },
  },
  beforeMount() {
    // reset to default environments list every time we open the drawer
    // and re-render the environments scope dropdown
    this.$emit('search-environment-scope', '');
  },
  mounted() {
    if (this.isProtectedByDefault && !this.isEditing) {
      this.variable = { ...this.variable, protected: true };
    }
  },
  methods: {
    close() {
      this.$emit('close-form');
    },
    deleteVariable() {
      this.$emit('delete-variable', this.variable);
      this.close();
    },
    getTrackingErrorProperty() {
      if (this.isValueEmpty) {
        return null;
      }

      let property;
      if (this.isValueMaskable) {
        property = this.variable.value.replace(this.maskedSupportedCharsRegEx, '');
      } else if (this.hasVariableReference) {
        property = '$';
      }

      return property;
    },
    hideMutationAlert() {
      this.isMutationAlertVisible = false;
    },
    resetForm() {
      this.variable = { ...defaultVariableState };
    },
    setEnvironmentScope(scope) {
      this.variable = { ...this.variable, environmentScope: scope };
    },
    setRaw(expanded) {
      this.variable = { ...this.variable, raw: !expanded };
    },
    showMutationAlert() {
      this.isMutationAlertVisible = true;
    },
    submit() {
      this.$emit(this.isEditing ? 'update-variable' : 'add-variable', this.variable);
    },
    trackVariableValidationErrors() {
      const property = this.getTrackingErrorProperty();
      if (property && !this.trackedValidationErrorProperty) {
        this.track(EVENT_ACTION, { property });
        this.trackedValidationErrorProperty = property;
      }
    },
  },
  awsTokenList,
  flagLink: helpPagePath('ci/variables/index', {
    anchor: 'define-a-cicd-variable-in-the-ui',
  }),
  variablesPrecedenceLink: helpPagePath('ci/variables/index', {
    anchor: 'cicd-variable-precedence',
  }),
  i18n,
  variableOptions,
  deleteModal: {
    actionPrimary: {
      text: __('Delete'),
      attributes: {
        variant: 'danger',
      },
    },
    actionSecondary: {
      text: __('Cancel'),
      attributes: {
        variant: 'default',
      },
    },
  },
};
</script>
<template>
  <div>
    <gl-drawer
      open
      data-testid="ci-variable-drawer"
      :header-height="getDrawerHeaderHeight"
      :z-index="$options.DRAWER_Z_INDEX"
      @close="close"
    >
      <template #title>
        <h2 class="gl-m-0">{{ modalTitle }}</h2>
      </template>
      <gl-alert
        v-if="isMutationAlertVisible"
        :variant="mutationAlertVariant"
        class="gl-m-4 gl-pl-9! gl-border-bottom-0"
        data-testid="ci-variable-mutation-alert"
        @dismiss="hideMutationAlert"
      >
        {{ mutationResponse.message }}
      </gl-alert>
      <gl-form-group
        :label="$options.i18n.type"
        label-for="ci-variable-type"
        class="gl-border-none"
        :class="{
          'gl-mb-n5': !hideEnvironmentScope,
          'gl-mb-n1': hideEnvironmentScope,
        }"
      >
        <gl-form-select
          id="ci-variable-type"
          v-model="variable.variableType"
          :options="$options.variableOptions"
        />
      </gl-form-group>
      <gl-form-group
        v-if="!hideEnvironmentScope"
        class="gl-border-none gl-mb-n5"
        label-for="ci-variable-env"
        data-testid="environment-scope"
      >
        <template #label>
          <div class="gl-display-flex gl-align-items-center">
            <span class="gl-mr-2">
              {{ $options.i18n.environments }}
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
          class="gl-mb-5"
          :are-environments-loading="areEnvironmentsLoading"
          :environments="environments"
          :selected-environment-scope="variable.environmentScope"
          @select-environment="setEnvironmentScope"
          @search-environment-scope="$emit('search-environment-scope', $event)"
        />
        <gl-form-input
          v-else
          :value="$options.i18n.defaultScope"
          class="gl-w-full gl-mb-5"
          readonly
        />
      </gl-form-group>
      <gl-form-group class="gl-border-none gl-mb-n8">
        <template #label>
          <div class="gl-display-flex gl-align-items-center gl-mb-n3">
            <span class="gl-mr-2">
              {{ $options.i18n.flags }}
            </span>
            <gl-link
              class="gl-display-flex"
              :title="$options.i18n.flagsLinkTitle"
              :href="$options.flagLink"
              data-testid="ci-variable-flags-docs-link"
              target="_blank"
            >
              <gl-icon name="question-o" :size="14" />
            </gl-link>
          </div>
        </template>
        <gl-form-checkbox v-model="variable.protected" data-testid="ci-variable-protected-checkbox">
          {{ $options.i18n.protectedField }}
          <p class="gl-text-secondary">
            {{ $options.i18n.protectedDescription }}
          </p>
        </gl-form-checkbox>
        <gl-form-checkbox v-model="variable.masked" data-testid="ci-variable-masked-checkbox">
          {{ $options.i18n.maskedField }}
          <p class="gl-text-secondary">{{ $options.i18n.maskedDescription }}</p>
        </gl-form-checkbox>
        <gl-form-checkbox
          data-testid="ci-variable-expanded-checkbox"
          :checked="isExpanded"
          @change="setRaw"
        >
          {{ $options.i18n.expandedField }}
          <p class="gl-text-secondary">
            <gl-sprintf :message="$options.i18n.expandedDescription" class="gl-text-secondary">
              <template #code="{ content }">
                <code>{{ content }}</code>
              </template>
            </gl-sprintf>
          </p>
        </gl-form-checkbox>
      </gl-form-group>
      <gl-form-group
        label-for="ci-variable-description"
        :label="$options.i18n.description"
        class="gl-border-none gl-mb-n5"
        data-testid="ci-variable-description-label"
        :description="$options.i18n.descriptionHelpText"
        optional
      >
        <gl-form-input
          id="ci-variable-description"
          v-model="variable.description"
          class="gl-border-none"
          data-testid="ci-variable-description"
        />
      </gl-form-group>
      <gl-form-combobox
        v-model="variable.key"
        :token-list="$options.awsTokenList"
        :label-text="$options.i18n.key"
        class="gl-border-none gl-pb-0! gl-mb-n5"
        data-testid="ci-variable-key"
      />
      <p
        v-if="variable.key.length > 0 && !isKeyValid"
        class="gl-pt-3! gl-pb-0! gl-mb-0 gl-text-red-500 gl-border-none"
      >
        {{ $options.i18n.keyFeedback }}
      </p>
      <p class="gl-pt-3! gl-pb-0! gl-mb-0 gl-text-secondary gl-border-none">
        <gl-sprintf :message="$options.i18n.keyHelpText">
          <template #link="{ content }"
            ><gl-link
              :href="$options.variablesPrecedenceLink"
              data-testid="ci-variable-precedence-docs-link"
              >{{ content }}</gl-link
            >
          </template>
        </gl-sprintf>
      </p>
      <gl-form-group
        :label="$options.i18n.value"
        label-for="ci-variable-value"
        class="gl-border-none gl-mb-n2"
        data-testid="ci-variable-value-label"
        :invalid-feedback="maskedValidationIssuesText"
        :state="isValueValid"
      >
        <gl-form-textarea
          id="ci-variable-value"
          v-model="variable.value"
          :spellcheck="false"
          class="gl-border-none gl-font-monospace!"
          rows="5"
          :no-resize="false"
          data-testid="ci-variable-value"
        />
        <p
          v-if="variable.raw"
          class="gl-mt-2 gl-mb-0 text-secondary"
          data-testid="raw-variable-tip"
        >
          {{ $options.i18n.valueFeedback.rawHelpText }}
        </p>
      </gl-form-group>
      <gl-alert
        v-if="hasVariableReference"
        :title="$options.i18n.variableReferenceTitle"
        :dismissible="false"
        variant="warning"
        class="gl-mx-4 gl-pl-9! gl-border-bottom-0"
        data-testid="has-variable-reference-alert"
      >
        {{ $options.i18n.variableReferenceDescription }}
      </gl-alert>
      <div class="gl-display-flex">
        <gl-button
          category="primary"
          class="gl-mr-3"
          variant="confirm"
          :disabled="!canSubmit"
          data-testid="ci-variable-confirm-button"
          @click="submit"
          >{{ modalActionText }}
        </gl-button>
        <gl-button
          v-if="isEditing"
          v-gl-modal-directive="`delete-variable-${variable.key}`"
          variant="danger"
          category="secondary"
          class="gl-mr-3"
          data-testid="ci-variable-delete-button"
          >{{ $options.i18n.deleteVariable }}</gl-button
        >
        <gl-button category="secondary" class="gl-mr-3" data-testid="cancel-button" @click="close"
          >{{ $options.i18n.cancel }}
        </gl-button>
      </div>
    </gl-drawer>
    <gl-modal
      ref="modal"
      :modal-id="`delete-variable-${variable.key}`"
      :title="$options.i18n.deleteVariable"
      :action-primary="$options.deleteModal.actionPrimary"
      :action-secondary="$options.deleteModal.actionSecondary"
      data-testid="ci-variable-drawer-confirm-delete-modal"
      @primary="deleteVariable"
    >
      {{ removeVariableMessage }}
    </gl-modal>
  </div>
</template>
