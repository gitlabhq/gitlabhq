<script>
import { mapState, mapActions } from 'vuex';
import CustomVariable from './variables/custom_variable.vue';
import TextVariable from './variables/text_variable.vue';
import { setCustomVariablesFromUrl } from '../utils';

export default {
  components: {
    CustomVariable,
    TextVariable,
  },
  computed: {
    ...mapState('monitoringDashboard', ['variables']),
  },
  methods: {
    ...mapActions('monitoringDashboard', ['updateVariablesAndFetchData']),
    refreshDashboard(variable, value) {
      if (this.variables[variable].value !== value) {
        const changedVariable = { key: variable, value };
        // update the Vuex store
        this.updateVariablesAndFetchData(changedVariable);
        // the below calls can ideally be moved out of the
        // component and into the actions and let the
        // mutation respond directly.
        // This can be further investigate in
        // https://gitlab.com/gitlab-org/gitlab/-/issues/217713
        setCustomVariablesFromUrl(this.variables);
      }
    },
    variableComponent(type) {
      const types = {
        text: TextVariable,
        custom: CustomVariable,
      };
      return types[type] || TextVariable;
    },
  },
};
</script>
<template>
  <div ref="variablesSection" class="d-sm-flex flex-sm-wrap pt-2 pr-1 pb-0 pl-2 variables-section">
    <div v-for="(variable, key) in variables" :key="key" class="mb-1 pr-2 d-flex d-sm-block">
      <component
        :is="variableComponent(variable.type)"
        class="mb-0 flex-grow-1"
        :label="variable.label"
        :value="variable.value"
        :name="key"
        :options="variable.options"
        @onUpdate="refreshDashboard"
      />
    </div>
  </div>
</template>
