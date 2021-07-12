<script>
import { GlButton, GlLink, GlSprintf } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { mapActions } from 'vuex';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';

export default {
  name: 'ManualVariablesForm',
  components: {
    GlButton,
    GlLink,
    GlSprintf,
  },
  props: {
    action: {
      type: Object,
      required: false,
      default: null,
      validator(value) {
        return (
          value === null ||
          (Object.prototype.hasOwnProperty.call(value, 'path') &&
            Object.prototype.hasOwnProperty.call(value, 'method') &&
            Object.prototype.hasOwnProperty.call(value, 'button_title'))
        );
      },
    },
  },
  inputTypes: {
    key: 'key',
    value: 'value',
  },
  i18n: {
    keyPlaceholder: s__('CiVariables|Input variable key'),
    valuePlaceholder: s__('CiVariables|Input variable value'),
    formHelpText: s__(
      'CiVariables|Specify variable values to be used in this run. The values specified in %{linkStart}CI/CD settings%{linkEnd} will be used as default',
    ),
  },
  data() {
    return {
      variables: [],
      key: '',
      secretValue: '',
      triggerBtnDisabled: false,
    };
  },
  computed: {
    variableSettings() {
      return helpPagePath('ci/variables/index', { anchor: 'add-a-cicd-variable-to-a-project' });
    },
  },
  watch: {
    key(newVal) {
      this.handleValueChange(newVal, this.$options.inputTypes.key);
    },
    secretValue(newVal) {
      this.handleValueChange(newVal, this.$options.inputTypes.value);
    },
  },
  methods: {
    ...mapActions(['triggerManualJob']),
    handleValueChange(newValue, type) {
      if (newValue !== '') {
        this.createNewVariable(type);
        this.resetForm();
      }
    },
    createNewVariable(type) {
      const newVariable = {
        key: this.key,
        secret_value: this.secretValue,
        id: uniqueId(),
      };

      this.variables.push(newVariable);

      return this.$nextTick().then(() => {
        this.$refs[`${this.$options.inputTypes[type]}-${newVariable.id}`][0].focus();
      });
    },
    resetForm() {
      this.key = '';
      this.secretValue = '';
    },
    deleteVariable(id) {
      this.variables.splice(
        this.variables.findIndex((el) => el.id === id),
        1,
      );
    },
    trigger() {
      this.triggerBtnDisabled = true;

      this.triggerManualJob(this.variables);
    },
  },
};
</script>
<template>
  <div class="col-12" data-testid="manual-vars-form">
    <label>{{ s__('CiVariables|Variables') }}</label>

    <div class="ci-table">
      <div class="gl-responsive-table-row table-row-header pb-0 pt-0 border-0" role="row">
        <div class="table-section section-50" role="rowheader">{{ s__('CiVariables|Key') }}</div>
        <div class="table-section section-50" role="rowheader">{{ s__('CiVariables|Value') }}</div>
      </div>

      <div
        v-for="variable in variables"
        :key="variable.id"
        class="gl-responsive-table-row"
        data-testid="ci-variable-row"
      >
        <div class="table-section section-50">
          <div class="table-mobile-header" role="rowheader">{{ s__('Pipeline|Key') }}</div>
          <div class="table-mobile-content gl-mr-3">
            <input
              :ref="`${$options.inputTypes.key}-${variable.id}`"
              v-model="variable.key"
              :placeholder="$options.i18n.keyPlaceholder"
              class="ci-variable-body-item form-control"
              data-testid="ci-variable-key"
            />
          </div>
        </div>

        <div class="table-section section-50">
          <div class="table-mobile-header" role="rowheader">{{ s__('Pipeline|Value') }}</div>
          <div class="table-mobile-content gl-mr-3">
            <input
              :ref="`${$options.inputTypes.value}-${variable.id}`"
              v-model="variable.secret_value"
              :placeholder="$options.i18n.valuePlaceholder"
              class="ci-variable-body-item form-control"
              data-testid="ci-variable-value"
            />
          </div>
        </div>

        <div class="table-section section-10">
          <div class="table-mobile-header" role="rowheader"></div>
          <div class="table-mobile-content justify-content-end">
            <gl-button
              category="tertiary"
              icon="clear"
              :aria-label="__('Delete variable')"
              data-testid="delete-variable-btn"
              @click="deleteVariable(variable.id)"
            />
          </div>
        </div>
      </div>
      <div class="gl-responsive-table-row">
        <div class="table-section section-50">
          <div class="table-mobile-header" role="rowheader">{{ s__('Pipeline|Key') }}</div>
          <div class="table-mobile-content gl-mr-3">
            <input
              ref="inputKey"
              v-model="key"
              class="js-input-key form-control"
              :placeholder="$options.i18n.keyPlaceholder"
            />
          </div>
        </div>

        <div class="table-section section-50">
          <div class="table-mobile-header" role="rowheader">{{ s__('Pipeline|Value') }}</div>
          <div class="table-mobile-content gl-mr-3">
            <input
              ref="inputSecretValue"
              v-model="secretValue"
              class="ci-variable-body-item form-control"
              :placeholder="$options.i18n.valuePlaceholder"
            />
          </div>
        </div>
      </div>
    </div>
    <div class="gl-text-center gl-mt-3">
      <gl-sprintf :message="$options.i18n.formHelpText">
        <template #link="{ content }">
          <gl-link :href="variableSettings" target="_blank">
            {{ content }}
          </gl-link>
        </template>
      </gl-sprintf>
    </div>
    <div class="d-flex justify-content-center">
      <gl-button
        variant="info"
        category="primary"
        :aria-label="__('Trigger manual job')"
        :disabled="triggerBtnDisabled"
        data-testid="trigger-manual-job-btn"
        @click="trigger"
      >
        {{ action.button_title }}
      </gl-button>
    </div>
  </div>
</template>
