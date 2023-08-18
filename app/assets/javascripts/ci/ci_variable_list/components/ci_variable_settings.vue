<script>
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { ADD_VARIABLE_ACTION, EDIT_VARIABLE_ACTION, VARIABLE_ACTIONS } from '../constants';
import CiVariableDrawer from './ci_variable_drawer.vue';
import CiVariableTable from './ci_variable_table.vue';
import CiVariableModal from './ci_variable_modal.vue';

export default {
  components: {
    CiVariableDrawer,
    CiVariableTable,
    CiVariableModal,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    areEnvironmentsLoading: {
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
    hasEnvScopeQuery: {
      type: Boolean,
      required: true,
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
    useDrawerForm() {
      return this.glFeatures?.ciVariableDrawer;
    },
    showDrawer() {
      return this.showForm && this.useDrawerForm;
    },
    showModal() {
      return this.showForm && !this.useDrawerForm;
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
      <ci-variable-modal
        v-if="showModal"
        :are-environments-loading="areEnvironmentsLoading"
        :are-scoped-variables-available="areScopedVariablesAvailable"
        :environments="environments"
        :has-env-scope-query="hasEnvScopeQuery"
        :hide-environment-scope="hideEnvironmentScope"
        :variables="variables"
        :mode="mode"
        :selected-variable="selectedVariable"
        @add-variable="addVariable"
        @delete-variable="deleteVariable"
        @close-form="closeForm"
        @update-variable="updateVariable"
        @search-environment-scope="$emit('search-environment-scope', $event)"
      />
      <ci-variable-drawer
        v-if="showDrawer"
        :are-environments-loading="areEnvironmentsLoading"
        :are-scoped-variables-available="areScopedVariablesAvailable"
        :environments="environments"
        :hide-environment-scope="hideEnvironmentScope"
        :selected-variable="selectedVariable"
        :mode="mode"
        v-on="$listeners"
        @close-form="closeForm"
      />
    </div>
  </div>
</template>
