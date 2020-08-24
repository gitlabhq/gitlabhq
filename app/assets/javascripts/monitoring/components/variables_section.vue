<script>
import { mapState, mapActions } from 'vuex';
import DropdownField from './variables/dropdown_field.vue';
import TextField from './variables/text_field.vue';
import { setCustomVariablesFromUrl } from '../utils';
import { VARIABLE_TYPES } from '../constants';

export default {
  components: {
    DropdownField,
    TextField,
  },
  computed: {
    ...mapState('monitoringDashboard', ['variables']),
  },
  methods: {
    ...mapActions('monitoringDashboard', ['updateVariablesAndFetchData']),
    refreshDashboard(variable, value) {
      if (variable.value !== value) {
        this.updateVariablesAndFetchData({ name: variable.name, value });
        // update the Vuex store
        // the below calls can ideally be moved out of the
        // component and into the actions and let the
        // mutation respond directly.
        // This can be further investigate in
        // https://gitlab.com/gitlab-org/gitlab/-/issues/217713
        setCustomVariablesFromUrl(this.variables);
      }
    },
    variableField(type) {
      if (type === VARIABLE_TYPES.custom || type === VARIABLE_TYPES.metric_label_values) {
        return DropdownField;
      }
      return TextField;
    },
  },
};
</script>
<template>
  <div
    ref="variablesSection"
    class="d-sm-flex flex-sm-wrap pt-2 pr-1 pb-0 pl-2 variables-section"
    data-qa-selector="variables_content"
  >
    <div v-for="variable in variables" :key="variable.name" class="mb-1 pr-2 d-flex d-sm-block">
      <component
        :is="variableField(variable.type)"
        class="mb-0 flex-grow-1"
        :label="variable.label"
        :value="variable.value"
        :name="variable.name"
        :options="variable.options"
        data-qa-selector="variable_item"
        @input="refreshDashboard(variable, $event)"
      />
    </div>
  </div>
</template>
