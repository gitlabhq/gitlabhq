<script>
import Vue from 'vue';
import { s__, __ } from '~/locale';
import Api from '~/api';
import { redirectTo } from '~/lib/utils/url_utility';
import { VARIABLE_TYPE, FILE_TYPE } from '../constants';
import { uniqueId } from 'lodash';
import {
  GlAlert,
  GlButton,
  GlForm,
  GlFormGroup,
  GlFormInput,
  GlFormSelect,
  GlLink,
  GlNewDropdown,
  GlNewDropdownItem,
  GlSearchBoxByType,
  GlSprintf,
} from '@gitlab/ui';

export default {
  typeOptions: [
    { value: VARIABLE_TYPE, text: __('Variable') },
    { value: FILE_TYPE, text: __('File') },
  ],
  variablesDescription: s__(
    'Pipeline|Specify variable values to be used in this run. The values specified in %{linkStart}CI/CD settings%{linkEnd} will be used by default.',
  ),
  formElementClasses: 'gl-mr-3 gl-mb-3 table-section section-15',
  errorTitle: __('The form contains the following error:'),
  components: {
    GlAlert,
    GlButton,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlFormSelect,
    GlLink,
    GlNewDropdown,
    GlNewDropdownItem,
    GlSearchBoxByType,
    GlSprintf,
  },
  props: {
    pipelinesPath: {
      type: String,
      required: true,
    },
    projectId: {
      type: String,
      required: true,
    },
    refs: {
      type: Array,
      required: true,
    },
    settingsLink: {
      type: String,
      required: true,
    },
    fileParams: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    refParam: {
      type: String,
      required: false,
      default: '',
    },
    variableParams: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      searchTerm: '',
      refValue: this.refParam,
      variables: {},
      error: false,
    };
  },
  computed: {
    filteredRefs() {
      const lowerCasedSearchTerm = this.searchTerm.toLowerCase();
      return this.refs.filter(ref => ref.toLowerCase().includes(lowerCasedSearchTerm));
    },
    variablesLength() {
      return Object.keys(this.variables).length;
    },
  },
  created() {
    if (this.variableParams) {
      this.setVariableParams(VARIABLE_TYPE, this.variableParams);
    }

    if (this.fileParams) {
      this.setVariableParams(FILE_TYPE, this.fileParams);
    }

    this.addEmptyVariable();
  },
  methods: {
    addEmptyVariable() {
      this.variables[uniqueId('var')] = {
        variable_type: VARIABLE_TYPE,
        key: '',
        value: '',
      };
    },
    setVariableParams(type, paramsObj) {
      Object.entries(paramsObj).forEach(([key, value]) => {
        this.variables[uniqueId('var')] = {
          key,
          value,
          variable_type: type,
        };
      });
    },
    setRefSelected(ref) {
      this.refValue = ref;
    },
    isSelected(ref) {
      return ref === this.refValue;
    },
    insertNewVariable() {
      Vue.set(this.variables, uniqueId('var'), {
        variable_type: VARIABLE_TYPE,
        key: '',
        value: '',
      });
    },
    removeVariable(key) {
      Vue.delete(this.variables, key);
    },

    canRemove(index) {
      return index < this.variablesLength - 1;
    },
    createPipeline() {
      const filteredVariables = Object.values(this.variables).filter(
        ({ key, value }) => key !== '' && value !== '',
      );

      return Api.createPipeline(this.projectId, {
        ref: this.refValue,
        variables: filteredVariables,
      })
        .then(({ data }) => redirectTo(data.web_url))
        .catch(err => {
          this.error = err.response.data.message.base;
        });
    },
  },
};
</script>

<template>
  <gl-form @submit.prevent="createPipeline">
    <gl-alert
      v-if="error"
      :title="$options.errorTitle"
      :dismissible="false"
      variant="danger"
      class="gl-mb-4"
      >{{ error }}</gl-alert
    >
    <gl-form-group :label="s__('Pipeline|Run for')">
      <gl-new-dropdown :text="refValue" block>
        <gl-search-box-by-type
          v-model.trim="searchTerm"
          :placeholder="__('Search branches and tags')"
          class="gl-p-2"
        />
        <gl-new-dropdown-item
          v-for="(ref, index) in filteredRefs"
          :key="index"
          class="gl-font-monospace"
          is-check-item
          :is-checked="isSelected(ref)"
          @click="setRefSelected(ref)"
        >
          {{ ref }}
        </gl-new-dropdown-item>
      </gl-new-dropdown>

      <template #description>
        <div>
          {{ s__('Pipeline|Existing branch name or tag') }}
        </div></template
      >
    </gl-form-group>

    <gl-form-group :label="s__('Pipeline|Variables')">
      <div
        v-for="(value, key, index) in variables"
        :key="key"
        class="gl-display-flex gl-align-items-center gl-mb-4 gl-pb-2 gl-border-b-solid gl-border-gray-200 gl-border-b-1 gl-flex-direction-column gl-md-flex-direction-row"
        data-testid="ci-variable-row"
      >
        <gl-form-select
          v-model="variables[key].variable_type"
          :class="$options.formElementClasses"
          :options="$options.typeOptions"
        />
        <gl-form-input
          v-model="variables[key].key"
          :placeholder="s__('CiVariables|Input variable key')"
          :class="$options.formElementClasses"
          data-testid="pipeline-form-ci-variable-key"
          @change.once="insertNewVariable()"
        />
        <gl-form-input
          v-model="variables[key].value"
          :placeholder="s__('CiVariables|Input variable value')"
          class="gl-mr-5 gl-mb-3 table-section section-15"
        />
        <gl-button
          v-if="canRemove(index)"
          icon="issue-close"
          class="gl-mb-3"
          data-testid="remove-ci-variable-row"
          @click="removeVariable(key)"
        />
      </div>

      <template #description
        ><gl-sprintf :message="$options.variablesDescription">
          <template #link="{ content }">
            <gl-link :href="settingsLink">{{ content }}</gl-link>
          </template>
        </gl-sprintf></template
      >
    </gl-form-group>
    <div
      class="gl-border-t-solid gl-border-gray-100 gl-border-t-1 gl-p-5 gl-bg-gray-10 gl-display-flex gl-justify-content-space-between"
    >
      <gl-button type="submit" category="primary" variant="success">{{
        s__('Pipeline|Run Pipeline')
      }}</gl-button>
      <gl-button :href="pipelinesPath">{{ __('Cancel') }}</gl-button>
    </div>
  </gl-form>
</template>
