<script>
import { __ } from '~/locale';
import { mapActions, mapState } from 'vuex';
import { ADD_CI_VARIABLE_MODAL_ID } from '../constants';
import {
  GlButton,
  GlModal,
  GlFormSelect,
  GlFormGroup,
  GlFormInput,
  GlFormTextarea,
  GlFormCheckbox,
  GlLink,
  GlIcon,
} from '@gitlab/ui';

export default {
  modalId: ADD_CI_VARIABLE_MODAL_ID,
  components: {
    GlButton,
    GlModal,
    GlFormSelect,
    GlFormGroup,
    GlFormInput,
    GlFormTextarea,
    GlFormCheckbox,
    GlLink,
    GlIcon,
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
    ]),
    canSubmit() {
      if (this.variableData.masked && this.maskedState === false) {
        return false;
      }
      return this.variableData.key !== '' && this.variableData.secret_value !== '';
    },
    canMask() {
      const regex = RegExp(this.maskableRegex);
      return regex.test(this.variableData.secret_value);
    },
    displayMaskedError() {
      return !this.canMask && this.variableData.masked && this.variableData.secret_value !== '';
    },
    maskedState() {
      if (this.displayMaskedError) {
        return false;
      }
      return null;
    },
    variableData() {
      return this.variableBeingEdited || this.variable;
    },
    modalActionText() {
      return this.variableBeingEdited ? __('Update variable') : __('Add variable');
    },
    primaryAction() {
      return {
        text: this.modalActionText,
        attributes: { variant: 'success', disabled: !this.canSubmit },
      };
    },
    maskedFeedback() {
      return __('This variable can not be masked');
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
    ]),
    updateOrAddVariable() {
      if (this.variableBeingEdited) {
        this.updateVariable(this.variableBeingEdited);
      } else {
        this.addVariable();
      }
      this.hideModal();
    },
    resetModalHandler() {
      if (this.variableBeingEdited) {
        this.resetEditing();
      } else {
        this.clearModal();
      }
    },
    hideModal() {
      this.$refs.modal.hide();
    },
    deleteVarAndClose() {
      this.deleteVariable(this.variableBeingEdited);
      this.hideModal();
    },
  },
};
</script>

<template>
  <gl-modal
    ref="modal"
    :modal-id="$options.modalId"
    :title="modalActionText"
    @hidden="resetModalHandler"
  >
    <form>
      <gl-form-group :label="__('Key')" label-for="ci-variable-key">
        <gl-form-input
          id="ci-variable-key"
          v-model="variableData.key"
          data-qa-selector="variable_key"
        />
      </gl-form-group>

      <gl-form-group
        :label="__('Value')"
        label-for="ci-variable-value"
        :state="maskedState"
        :invalid-feedback="maskedFeedback"
      >
        <gl-form-textarea
          id="ci-variable-value"
          v-model="variableData.secret_value"
          rows="3"
          max-rows="6"
          data-qa-selector="variable_value"
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
          <gl-form-select
            id="ci-variable-env"
            v-model="variableData.environment_scope"
            :options="environments"
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
          data-qa-selector="variable_masked"
        >
          {{ __('Mask variable') }}
          <gl-link href="/help/ci/variables/README#masked-variables">
            <gl-icon name="question" :size="12" />
          </gl-link>
          <p class="prepend-top-4 append-bottom-0 text-secondary">
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
      <gl-button @click="hideModal">{{ __('Cancel') }}</gl-button>
      <gl-button
        v-if="variableBeingEdited"
        ref="deleteCiVariable"
        category="secondary"
        variant="danger"
        @click="deleteVarAndClose"
        >{{ __('Delete variable') }}</gl-button
      >
      <gl-button
        ref="updateOrAddVariable"
        :disabled="!canSubmit"
        variant="success"
        @click="updateOrAddVariable"
        >{{ modalActionText }}
      </gl-button>
    </template>
  </gl-modal>
</template>
