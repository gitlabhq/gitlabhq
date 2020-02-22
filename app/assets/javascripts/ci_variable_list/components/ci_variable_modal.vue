<script>
import { __ } from '~/locale';
import { mapActions, mapState } from 'vuex';
import { ADD_CI_VARIABLE_MODAL_ID } from '../constants';
import {
  GlModal,
  GlFormSelect,
  GlFormGroup,
  GlFormInput,
  GlFormCheckbox,
  GlLink,
  GlIcon,
} from '@gitlab/ui';

export default {
  modalId: ADD_CI_VARIABLE_MODAL_ID,
  components: {
    GlModal,
    GlFormSelect,
    GlFormGroup,
    GlFormInput,
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
      return this.variableData.key !== '' && this.variableData.secret_value !== '';
    },
    canMask() {
      const regex = RegExp(this.maskableRegex);
      return regex.test(this.variableData.secret_value);
    },
    variableData() {
      return this.variableBeingEdited || this.variable;
    },
    modalActionText() {
      return this.variableBeingEdited ? __('Update Variable') : __('Add variable');
    },
    primaryAction() {
      return {
        text: this.modalActionText,
        attributes: { variant: 'success', disabled: !this.canSubmit },
      };
    },
    cancelAction() {
      return {
        text: __('Cancel'),
      };
    },
  },
  methods: {
    ...mapActions([
      'addVariable',
      'updateVariable',
      'resetEditing',
      'displayInputValue',
      'clearModal',
    ]),
    updateOrAddVariable() {
      if (this.variableBeingEdited) {
        this.updateVariable(this.variableBeingEdited);
      } else {
        this.addVariable();
      }
    },
    resetModalHandler() {
      if (this.variableBeingEdited) {
        this.resetEditing();
      } else {
        this.clearModal();
      }
    },
  },
};
</script>

<template>
  <gl-modal
    :modal-id="$options.modalId"
    :title="modalActionText"
    :action-primary="primaryAction"
    :action-cancel="cancelAction"
    @ok="updateOrAddVariable"
    @hidden="resetModalHandler"
  >
    <form>
      <gl-form-group label="Type" label-for="ci-variable-type">
        <gl-form-select
          id="ci-variable-type"
          v-model="variableData.variable_type"
          :options="typeOptions"
        />
      </gl-form-group>

      <div class="d-flex">
        <gl-form-group label="Key" label-for="ci-variable-key" class="w-50 append-right-15">
          <gl-form-input
            id="ci-variable-key"
            v-model="variableData.key"
            type="text"
            data-qa-selector="variable_key"
          />
        </gl-form-group>

        <gl-form-group label="Value" label-for="ci-variable-value" class="w-50">
          <gl-form-input
            id="ci-variable-value"
            v-model="variableData.secret_value"
            type="text"
            data-qa-selector="variable_value"
          />
        </gl-form-group>
      </div>

      <gl-form-group v-if="!isGroup" label="Environment scope" label-for="ci-variable-env">
        <gl-form-select
          id="ci-variable-env"
          v-model="variableData.environment_scope"
          :options="environments"
        />
      </gl-form-group>

      <gl-form-group label="Flags" label-for="ci-variable-flags">
        <gl-form-checkbox v-model="variableData.protected" class="mb-0">
          {{ __('Protect variable') }}
          <gl-link href="/help/ci/variables/README#protected-environment-variables">
            <gl-icon name="question" :size="12" />
          </gl-link>
          <p class="prepend-top-4 clgray">
            {{ __('Allow variables to run on protected branches and tags.') }}
          </p>
        </gl-form-checkbox>

        <gl-form-checkbox
          ref="masked-ci-variable"
          v-model="variableData.masked"
          :disabled="!canMask"
          data-qa-selector="variable_masked"
        >
          {{ __('Mask variable') }}
          <gl-link href="/help/ci/variables/README#masked-variables">
            <gl-icon name="question" :size="12" />
          </gl-link>
          <p class="prepend-top-4 append-bottom-0 clgray">
            {{
              __(
                'Variables will be masked in job logs. Requires values to meet regular expression requirements.',
              )
            }}
            <gl-link href="/help/ci/variables/README#masked-variables">{{
              __('More information')
            }}</gl-link>
          </p>
        </gl-form-checkbox>
      </gl-form-group>
    </form>
  </gl-modal>
</template>
