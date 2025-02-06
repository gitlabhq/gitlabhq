<script>
import { isEqual, omit } from 'lodash';
import {
  GlAlert,
  GlButton,
  GlDrawer,
  GlFormCheckbox,
  GlFormCombobox,
  GlFormGroup,
  GlFormInput,
  GlCollapsibleListbox,
  GlFormTextarea,
  GlLink,
  GlModal,
  GlModalDirective,
  GlSprintf,
  GlFormRadio,
  GlFormRadioGroup,
  GlPopover,
} from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { helpPagePath } from '~/helpers/help_page_helper';
import Tracking from '~/tracking';
import CiEnvironmentsDropdown from '~/ci/common/private/ci_environments_dropdown';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';
import {
  defaultVariableState,
  ADD_VARIABLE_ACTION,
  DRAWER_EVENT_LABEL,
  EDIT_VARIABLE_ACTION,
  EVENT_ACTION,
  EXPANDED_VARIABLES_NOTE,
  MASKED_VALUE_MIN_LENGTH,
  VARIABLE_ACTIONS,
  VISIBILITY_HIDDEN,
  VISIBILITY_MASKED,
  VISIBILITY_VISIBLE,
  visibilityToAttributesMap,
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
  expandedField: s__('CiVariables|Expand variable reference'),
  expandedDescription: EXPANDED_VARIABLES_NOTE,
  flags: __('Flags'),
  visibility: __('Visibility'),
  key: __('Key'),
  keyFeedback: s__("CiVariables|A variable key can only contain letters, numbers, and '_'."),
  keyHelpText: s__(
    'CiVariables|You can use CI/CD variables with the same name in different places, but the variables might overwrite each other. %{linkStart}What is the order of precedence for variables?%{linkEnd}',
  ),
  maskedAndHiddenField: s__('CiVariables|Masked and hidden'),
  maskedField: s__('CiVariables|Masked'),
  visibleField: s__('CiVariables|Visible'),
  maskedAndHiddenDescription: s__(
    'CiVariables|Masked in job logs, and can never be revealed in the CI/CD settings after the variable is saved.',
  ),
  maskedDescription: s__(
    'CiVariables|Masked in job logs but value can be revealed in CI/CD settings. Requires values to meet regular expressions requirements.',
  ),
  visibleDescription: s__('CiVariables|Can be seen in job logs.'),
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
  variableIsHidden: s__('CiVariables|The value is masked and hidden permanently.'),
  variableReferenceTitle: s__('CiVariables|Value might contain a variable reference'),
  variableReferenceDescription: s__(
    'CiVariables|Unselect "Expand variable reference" if you want to use the variable value as a raw string.',
  ),
  whitespaceCharsValidationText: s__(
    'CiVariables|This value cannot be masked because it contains the following characters: whitespace characters.',
  ),
  environmentsLabelHelpText: s__(
    'CiVariables|You can use a specific environment name like %{codeStart}production%{codeEnd}, or include a wildcard (%{codeStart}*%{codeEnd}) to match multiple environments, like %{codeStart}review*%{codeEnd}.',
  ),
  environmentsLabelLinkText: s__(
    'CiVariables|Learn how to %{linkStart}restrict CI/CD variables to specific environments%{linkEnd} for better security.',
  ),
  visibilityLabelHelpText: s__(
    "CiVariables|Set the visibility level for the variable's value. The %{linkStart}Masked and hidden%{linkEnd} option is only available for new variables. You cannot update an existing variable to be hidden.",
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
    GlCollapsibleListbox,
    GlFormTextarea,
    GlLink,
    GlModal,
    GlSprintf,
    GlFormRadio,
    GlFormRadioGroup,
    GlPopover,
    HelpIcon,
  },
  directives: {
    GlModalDirective,
  },
  mixins: [trackingMixin],
  inject: ['isProtectedByDefault', 'maskableRawRegex', 'maskableRegex'],
  props: {
    areEnvironmentsLoading: {
      type: Boolean,
      required: true,
    },
    areHiddenVariablesAvailable: {
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
      visibility: VISIBILITY_VISIBLE,
      trackedValidationErrorProperty: undefined,
    };
  },
  computed: {
    isValueMaskable() {
      return this.variable.masked && !this.isEditingHiddenVariable && !this.isValueMasked;
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
      return !this.variable.masked || this.isEditingHiddenVariable || this.isValueMasked;
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
    isEditingHiddenVariable() {
      return this.selectedVariable.hidden && this.isEditing;
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
    variableToEmit() {
      if (this.isEditingHiddenVariable) {
        return omit(this.variable, 'value');
      }
      return this.variable;
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

    // translate masked and hidden flags to visibility options
    let visibility = VISIBILITY_VISIBLE;
    if (this.variable.hidden) visibility = VISIBILITY_HIDDEN;
    else if (this.variable.masked) visibility = VISIBILITY_MASKED;

    this.visibility = visibility;
  },
  methods: {
    close() {
      this.$emit('close-form');
    },
    deleteVariable() {
      this.$emit('delete-variable', this.variableToEmit);
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

      this.visibility = VISIBILITY_VISIBLE;
    },
    setEnvironmentScope(scope) {
      this.variable = { ...this.variable, environmentScope: scope };
    },
    setRaw(expanded) {
      this.variable = { ...this.variable, raw: !expanded };
    },
    setVisibility(visibility) {
      this.visibility = visibility;
      this.variable = {
        ...this.variable,
        ...visibilityToAttributesMap[visibility],
      };
    },
    showMutationAlert() {
      this.isMutationAlertVisible = true;
    },
    submit() {
      this.$emit(this.isEditing ? 'update-variable' : 'add-variable', this.variableToEmit);
      this.$refs.drawer.$el.scrollTo({ top: 0, behavior: 'smooth' });
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
  variablesPrecedenceLink: helpPagePath('ci/variables/_index', {
    anchor: 'cicd-variable-precedence',
  }),
  environmentsLabelHelpLink: helpPagePath('ci/environments/_index', {
    anchor: 'limit-the-environment-scope-of-a-cicd-variable',
  }),
  visibilityLabelHelpLink: helpPagePath('ci/variables/_index', {
    anchor: 'hide-a-cicd-variable',
  }),
  environmentsPopoverContainerId: 'environments-popover-container',
  environmentsPopoverTargetId: 'environments-popover-target',
  visibilityPopoverContainerId: 'visibility-popover-container',
  visibilityPopoverTargetId: 'visibility-popover-target',
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
  VISIBILITY_HIDDEN,
  VISIBILITY_MASKED,
  VISIBILITY_VISIBLE,
};
</script>
<template>
  <div>
    <gl-drawer
      ref="drawer"
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
        class="gl-m-4 gl-border-b-0 !gl-pl-9"
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
          '-gl-mb-5': !hideEnvironmentScope,
          '-gl-mb-1': hideEnvironmentScope,
        }"
      >
        <gl-collapsible-listbox
          v-model="variable.variableType"
          :items="$options.variableOptions"
          block
          fluid-width
        />
      </gl-form-group>
      <gl-form-group
        v-if="!hideEnvironmentScope"
        class="-gl-mb-5 gl-border-none"
        label-for="ci-variable-env"
        data-testid="environment-scope"
      >
        <template #label>
          <div class="gl-flex gl-items-center">
            <span class="gl-mr-2">
              {{ $options.i18n.environments }}
            </span>
            <span
              :id="$options.environmentsPopoverContainerId"
              :data-testid="$options.environmentsPopoverContainerId"
            >
              <help-icon :id="$options.environmentsPopoverTargetId" />
              <gl-popover
                :target="$options.environmentsPopoverTargetId"
                :container="$options.environmentsPopoverContainerId"
              >
                <gl-sprintf :message="$options.i18n.environmentsLabelHelpText">
                  <template #code="{ content }">
                    <code>{{ content }}</code>
                  </template>
                </gl-sprintf>
                <br /><br />
                <gl-sprintf :message="$options.i18n.environmentsLabelLinkText">
                  <template #link="{ content }">
                    <gl-link :href="$options.environmentsLabelHelpLink">{{ content }}</gl-link>
                  </template>
                </gl-sprintf>
              </gl-popover>
            </span>
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
          class="gl-mb-5 gl-w-full"
          readonly
        />
      </gl-form-group>
      <gl-form-group class="-gl-mb-3 gl-border-none">
        <template #label>
          <div class="-gl-mb-3">
            {{ $options.i18n.visibility }}
            <span
              :id="$options.visibilityPopoverContainerId"
              :data-testid="$options.visibilityPopoverContainerId"
            >
              <help-icon :id="$options.visibilityPopoverTargetId" />
              <gl-popover
                :target="$options.visibilityPopoverTargetId"
                :container="$options.visibilityPopoverContainerId"
              >
                <gl-sprintf :message="$options.i18n.visibilityLabelHelpText">
                  <template #link="{ content }">
                    <gl-link :href="$options.visibilityLabelHelpLink">{{ content }}</gl-link>
                  </template>
                </gl-sprintf>
              </gl-popover>
            </span>
          </div>
        </template>
        <gl-form-radio-group
          v-model="visibility"
          :disabled="isEditingHiddenVariable"
          data-testid="ci-variable-visibility"
          @change="setVisibility"
        >
          <gl-form-radio
            :value="$options.VISIBILITY_VISIBLE"
            data-testid="ci-variable-visible-radio"
          >
            {{ $options.i18n.visibleField }}
            <template #help>{{ $options.i18n.visibleDescription }}</template>
          </gl-form-radio>
          <gl-form-radio :value="$options.VISIBILITY_MASKED" data-testid="ci-variable-masked-radio">
            {{ $options.i18n.maskedField }}
            <template #help>{{ $options.i18n.maskedDescription }}</template>
          </gl-form-radio>
          <gl-form-radio
            v-if="areHiddenVariablesAvailable"
            :value="$options.VISIBILITY_HIDDEN"
            data-testid="ci-variable-masked-and-hidden-radio"
          >
            {{ $options.i18n.maskedAndHiddenField }}
            <template #help>
              {{ $options.i18n.maskedAndHiddenDescription }}
            </template>
          </gl-form-radio>
        </gl-form-radio-group>
      </gl-form-group>
      <gl-form-group class="-gl-mb-8 gl-border-none">
        <template #label>
          <div class="-gl-mb-3 gl-flex gl-items-center">
            {{ $options.i18n.flags }}
          </div>
        </template>
        <gl-form-checkbox v-model="variable.protected" data-testid="ci-variable-protected-checkbox">
          {{ $options.i18n.protectedField }}
          <p class="gl-text-subtle">
            {{ $options.i18n.protectedDescription }}
          </p>
        </gl-form-checkbox>
        <gl-form-checkbox
          data-testid="ci-variable-expanded-checkbox"
          :checked="isExpanded"
          @change="setRaw"
        >
          {{ $options.i18n.expandedField }}
          <p class="gl-text-subtle">
            <gl-sprintf :message="$options.i18n.expandedDescription" class="gl-text-subtle">
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
        class="-gl-mb-5 gl-border-none"
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
        class="-gl-mb-5 gl-border-none !gl-pb-0"
        data-testid="ci-variable-key"
      />
      <p
        v-if="variable.key.length > 0 && !isKeyValid"
        class="gl-mb-0 gl-border-none !gl-pb-0 !gl-pt-3 gl-text-red-500"
      >
        {{ $options.i18n.keyFeedback }}
      </p>
      <p class="gl-mb-0 gl-border-none !gl-pb-0 !gl-pt-3 gl-text-subtle">
        <gl-sprintf :message="$options.i18n.keyHelpText">
          <template #link="{ content }">
            <gl-link
              :href="$options.variablesPrecedenceLink"
              data-testid="ci-variable-precedence-docs-link"
            >
              {{ content }}
            </gl-link>
          </template>
        </gl-sprintf>
      </p>
      <gl-form-group
        :label="$options.i18n.value"
        label-for="ci-variable-value"
        class="-gl-mb-2 gl-border-none"
        data-testid="ci-variable-value-label"
        :invalid-feedback="maskedValidationIssuesText"
        :state="isValueValid"
      >
        <p v-if="isEditingHiddenVariable" class="gl-mb-0 gl-mt-2" data-testid="hidden-variable-tip">
          {{ $options.i18n.variableIsHidden }}
        </p>
        <gl-form-textarea
          v-else
          id="ci-variable-value"
          v-model="variable.value"
          :spellcheck="false"
          class="gl-border-none !gl-font-monospace"
          rows="5"
          :no-resize="false"
          data-testid="ci-variable-value"
        />
        <p
          v-if="variable.raw"
          class="gl-mb-0 gl-mt-2 gl-text-subtle"
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
        class="gl-mx-4 gl-border-b-0 !gl-pl-9"
        data-testid="has-variable-reference-alert"
      >
        {{ $options.i18n.variableReferenceDescription }}
      </gl-alert>
      <div class="gl-mb-5 gl-flex gl-gap-3">
        <gl-button
          category="primary"
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
          data-testid="ci-variable-delete-button"
        >
          {{ $options.i18n.deleteVariable }}
        </gl-button>
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
