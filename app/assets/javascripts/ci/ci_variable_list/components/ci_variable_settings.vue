<script>
import { ADD_VARIABLE_ACTION, EDIT_VARIABLE_ACTION, VARIABLE_ACTIONS } from '../constants';
import CiVariableTable from './ci_variable_table.vue';
import CiVariableModal from './ci_variable_modal.vue';

export default {
  components: {
    CiVariableTable,
    CiVariableModal,
  },
  props: {
    areScopedVariablesAvailable: {
      type: Boolean,
      required: false,
      default: false,
    },
    entity: {
      type: String,
      required: false,
      default: '',
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
    isLoading: {
      type: Boolean,
      required: false,
    },
    maxVariableLimit: {
      type: Number,
      required: false,
      default: 0,
    },
    variables: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      selectedVariable: {},
      mode: null,
    };
  },
  computed: {
    showModal() {
      return VARIABLE_ACTIONS.includes(this.mode);
    },
  },
  methods: {
    addVariable(variable) {
      this.$emit('add-variable', variable);
    },
    deleteVariable(variable) {
      this.$emit('delete-variable', variable);
    },
    updateVariable(variable) {
      this.$emit('update-variable', variable);
    },
    hideModal() {
      this.mode = null;
    },
    setSelectedVariable(variable = null) {
      if (!variable) {
        this.selectedVariable = {};
        this.mode = ADD_VARIABLE_ACTION;
      } else {
        this.selectedVariable = variable;
        this.mode = EDIT_VARIABLE_ACTION;
      }
    },
  },
};
</script>

<template>
  <div class="row">
    <div class="col-lg-12">
      <ci-variable-table
        :entity="entity"
        :is-loading="isLoading"
        :max-variable-limit="maxVariableLimit"
        :variables="variables"
        @set-selected-variable="setSelectedVariable"
      />
      <ci-variable-modal
        v-if="showModal"
        :are-scoped-variables-available="areScopedVariablesAvailable"
        :environments="environments"
        :hide-environment-scope="hideEnvironmentScope"
        :variables="variables"
        :mode="mode"
        :selected-variable="selectedVariable"
        @add-variable="addVariable"
        @delete-variable="deleteVariable"
        @hideModal="hideModal"
        @update-variable="updateVariable"
      />
    </div>
  </div>
</template>
