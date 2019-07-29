<script>
import _ from 'underscore';
import { mapActions } from 'vuex';
import { GlButton } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  name: 'ManualVariablesForm',
  components: {
    GlButton,
    Icon,
  },
  props: {
    action: {
      type: Object,
      required: false,
      default: null,
      validator(value) {
        return (
          value === null ||
          (_.has(value, 'path') && _.has(value, 'method') && _.has(value, 'button_title'))
        );
      },
    },
    variablesSettingsUrl: {
      type: String,
      required: true,
      default: '',
    },
  },
  inputTypes: {
    key: 'key',
    value: 'value',
  },
  i18n: {
    keyPlaceholder: s__('CiVariables|Input variable key'),
    valuePlaceholder: s__('CiVariables|Input variable value'),
  },
  data() {
    return {
      variables: [],
      key: '',
      secretValue: '',
    };
  },
  computed: {
    helpText() {
      return sprintf(
        s__(
          'CiVariables|Specify variable values to be used in this run. The values specified in %{linkStart}CI/CD settings%{linkEnd} will be used as default',
        ),
        {
          linkStart: `<a href="${this.variablesSettingsUrl}">`,
          linkEnd: '</a>',
        },
        false,
      );
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
        id: _.uniqueId(),
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
      this.variables.splice(this.variables.findIndex(el => el.id === id), 1);
    },
  },
};
</script>
<template>
  <div class="js-manual-vars-form col-12">
    <label>{{ s__('CiVariables|Variables') }}</label>

    <div class="ci-table">
      <div class="gl-responsive-table-row table-row-header pb-0 pt-0 border-0" role="row">
        <div class="table-section section-50" role="rowheader">{{ s__('CiVariables|Key') }}</div>
        <div class="table-section section-50" role="rowheader">{{ s__('CiVariables|Value') }}</div>
      </div>

      <div v-for="variable in variables" :key="variable.id" class="gl-responsive-table-row">
        <div class="table-section section-50">
          <div class="table-mobile-header" role="rowheader">{{ s__('Pipeline|Key') }}</div>
          <div class="table-mobile-content append-right-10">
            <input
              :ref="`${$options.inputTypes.key}-${variable.id}`"
              v-model="variable.key"
              :placeholder="$options.i18n.keyPlaceholder"
              class="ci-variable-body-item form-control"
            />
          </div>
        </div>

        <div class="table-section section-50">
          <div class="table-mobile-header" role="rowheader">{{ s__('Pipeline|Value') }}</div>
          <div class="table-mobile-content append-right-10">
            <input
              :ref="`${$options.inputTypes.value}-${variable.id}`"
              v-model="variable.secret_value"
              :placeholder="$options.i18n.valuePlaceholder"
              class="ci-variable-body-item form-control"
            />
          </div>
        </div>

        <div class="table-section section-10">
          <div class="table-mobile-header" role="rowheader"></div>
          <div class="table-mobile-content justify-content-end">
            <gl-button class="btn-transparent btn-blank w-25" @click="deleteVariable(variable.id)">
              <icon name="clear" />
            </gl-button>
          </div>
        </div>
      </div>
      <div class="gl-responsive-table-row">
        <div class="table-section section-50">
          <div class="table-mobile-header" role="rowheader">{{ s__('Pipeline|Key') }}</div>
          <div class="table-mobile-content append-right-10">
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
          <div class="table-mobile-content append-right-10">
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
    <div class="d-flex prepend-top-default justify-content-center">
      <p class="text-muted" v-html="helpText"></p>
    </div>
    <div class="d-flex justify-content-center">
      <gl-button variant="primary" @click="triggerManualJob(variables)">
        {{ action.button_title }}
      </gl-button>
    </div>
  </div>
</template>
