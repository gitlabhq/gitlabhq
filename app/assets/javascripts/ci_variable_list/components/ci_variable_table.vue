<script>
import { GlTable, GlButton, GlModalDirective, GlIcon } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { mapState, mapActions } from 'vuex';
import { ADD_CI_VARIABLE_MODAL_ID } from '../constants';

export default {
  modalId: ADD_CI_VARIABLE_MODAL_ID,
  fields: [
    {
      key: 'variable_type',
      label: s__('CiVariables|Type'),
    },
    {
      key: 'key',
      label: s__('CiVariables|Key'),
    },
    {
      key: 'value',
      label: s__('CiVariables|Value'),
      tdClass: 'qa-ci-variable-input-value',
    },
    {
      key: 'protected',
      label: s__('CiVariables|Protected'),
    },
    {
      key: 'masked',
      label: s__('CiVariables|Masked'),
    },
    {
      key: 'environment_scope',
      label: s__('CiVariables|Environment Scope'),
    },
    {
      key: 'actions',
      label: '',
    },
  ],
  components: {
    GlTable,
    GlButton,
    GlIcon,
  },
  directives: {
    GlModalDirective,
  },
  computed: {
    ...mapState(['variables', 'valuesHidden', 'isGroup', 'isLoading', 'isDeleting']),
    valuesButtonText() {
      return this.valuesHidden ? __('Reveal values') : __('Hide values');
    },
    tableIsNotEmpty() {
      return this.variables && this.variables.length > 0;
    },
    fields() {
      if (this.isGroup) {
        return this.$options.fields.filter(field => field.key !== 'environment_scope');
      }
      return this.$options.fields;
    },
  },
  mounted() {
    this.fetchVariables();
  },
  methods: {
    ...mapActions(['fetchVariables', 'deleteVariable', 'toggleValues', 'editVariable']),
  },
};
</script>

<template>
  <div class="ci-variable-table">
    <gl-table
      :fields="fields"
      :items="variables"
      responsive
      show-empty
      tbody-tr-class="js-ci-variable-row"
    >
      <template #cell(value)="data">
        <span v-if="valuesHidden">*****************</span>
        <span v-else>{{ data.value }}</span>
      </template>
      <template #cell(actions)="data">
        <gl-button
          ref="edit-ci-variable"
          v-gl-modal-directive="$options.modalId"
          @click="editVariable(data.item)"
        >
          <gl-icon name="pencil" />
        </gl-button>
        <gl-button
          ref="delete-ci-variable"
          category="secondary"
          variant="danger"
          @click="deleteVariable(data.item)"
        >
          <gl-icon name="remove" />
        </gl-button>
      </template>
      <template #empty>
        <p ref="empty-variables" class="settings-message text-center empty-variables">
          {{
            __(
              'There are currently no variables, add a variable with the Add Variable button below.',
            )
          }}
        </p>
      </template>
    </gl-table>
    <div class="ci-variable-actions d-flex justify-content-end">
      <gl-button
        v-if="tableIsNotEmpty"
        ref="secret-value-reveal-button"
        data-qa-selector="reveal_ci_variable_value"
        class="append-right-8"
        @click="toggleValues(!valuesHidden)"
        >{{ valuesButtonText }}</gl-button
      >
      <gl-button
        ref="add-ci-variable"
        v-gl-modal-directive="$options.modalId"
        data-qa-selector="add_ci_variable"
        variant="success"
        >{{ __('Add Variable') }}</gl-button
      >
    </div>
  </div>
</template>
