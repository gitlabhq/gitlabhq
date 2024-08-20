<script>
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { ADD_VARIABLE_ACTION, EDIT_VARIABLE_ACTION, VARIABLE_ACTIONS } from '../constants';
import CiVariableDrawer from './ci_variable_drawer.vue';
import CiVariableTable from './ci_variable_table.vue';

export default {
  components: {
    CiVariableDrawer,
    CiVariableTable,
  },
  mixins: [glFeatureFlagsMixin()],
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
    mutationResponse: {
      type: Object,
      required: false,
      default: null,
    },
    pageInfo: {
      type: Object,
      required: true,
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
    showForm() {
      return VARIABLE_ACTIONS.includes(this.mode);
    },
  },
  methods: {
    addVariable(variable) {
      this.$emit('add-variable', variable);
    },
    closeForm() {
      this.mode = null;
    },
    deleteVariable(variable) {
      this.$emit('delete-variable', variable);
    },
    updateVariable(variable) {
      this.$emit('update-variable', variable);
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
        :page-info="pageInfo"
        :variables="variables"
        @handle-prev-page="$emit('handle-prev-page')"
        @handle-next-page="$emit('handle-next-page')"
        @set-selected-variable="setSelectedVariable"
        @delete-variable="deleteVariable"
        @sort-changed="(val) => $emit('sort-changed', val)"
      />
      <ci-variable-drawer
        v-if="showForm"
        :are-environments-loading="areEnvironmentsLoading"
        :are-hidden-variables-available="areHiddenVariablesAvailable"
        :are-scoped-variables-available="areScopedVariablesAvailable"
        :environments="environments"
        :hide-environment-scope="hideEnvironmentScope"
        :selected-variable="selectedVariable"
        :mode="mode"
        :mutation-response="mutationResponse"
        @add-variable="addVariable"
        @close-form="closeForm"
        @delete-variable="deleteVariable"
        @update-variable="updateVariable"
        @search-environment-scope="$emit('search-environment-scope', $event)"
      />
    </div>
  </div>
</template>
