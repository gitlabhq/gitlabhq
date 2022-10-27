<script>
import { GlTable, GlButton, GlModalDirective, GlTooltipDirective } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import { s__, __ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { ADD_CI_VARIABLE_MODAL_ID } from '../constants';

export default {
  modalId: ADD_CI_VARIABLE_MODAL_ID,
  fields: [
    {
      key: 'variable_type',
      label: s__('CiVariables|Type'),
      thClass: 'gl-w-10p',
    },
    {
      key: 'key',
      label: s__('CiVariables|Key'),
      tdClass: 'text-plain',
      sortable: true,
    },
    {
      key: 'value',
      label: s__('CiVariables|Value'),
      thClass: 'gl-w-15p',
    },
    {
      key: 'options',
      label: s__('CiVariables|Options'),
      thClass: 'gl-w-10p',
    },
    {
      key: 'environment_scope',
      label: s__('CiVariables|Environments'),
    },
    {
      key: 'actions',
      label: '',
      tdClass: 'text-right',
      thClass: 'gl-w-5p',
    },
  ],
  components: {
    GlButton,
    GlTable,
  },
  directives: {
    GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagsMixin()],
  computed: {
    ...mapState(['variables', 'valuesHidden', 'isLoading', 'isDeleting']),
    valuesButtonText() {
      return this.valuesHidden ? __('Reveal values') : __('Hide values');
    },
    isTableEmpty() {
      return !this.variables || this.variables.length === 0;
    },
    fields() {
      return this.$options.fields;
    },
    variablesWithOptions() {
      return this.variables?.map((item, index) => ({
        ...item,
        options: this.getOptions(item),
        index,
      }));
    },
  },
  mounted() {
    this.fetchVariables();
  },
  methods: {
    ...mapActions(['fetchVariables', 'toggleValues', 'editVariable']),
    getOptions(item) {
      const options = [];
      if (item.protected) {
        options.push(s__('CiVariables|Protected'));
      }
      if (item.masked) {
        options.push(s__('CiVariables|Masked'));
      }
      return options.join(', ');
    },
    editVariableClicked(index = -1) {
      this.editVariable(this.variables[index] ?? null);
    },
  },
};
</script>

<template>
  <div class="ci-variable-table" data-testid="ci-variable-table">
    <gl-table
      :fields="fields"
      :items="variablesWithOptions"
      tbody-tr-class="js-ci-variable-row"
      data-qa-selector="ci_variable_table_content"
      sort-by="key"
      sort-direction="asc"
      stacked="lg"
      table-class="text-secondary"
      fixed
      show-empty
      sort-icon-left
      no-sort-reset
    >
      <template #table-colgroup="scope">
        <col v-for="field in scope.fields" :key="field.key" :style="field.customStyle" />
      </template>
      <template #cell(key)="{ item }">
        <div
          class="gl-display-flex gl-align-items-flex-start gl-justify-content-end gl-lg-justify-content-start gl-mr-n3"
        >
          <span
            :id="`ci-variable-key-${item.id}`"
            class="gl-display-inline-block gl-max-w-full gl-word-break-word"
            >{{ item.key }}</span
          >
          <gl-button
            v-gl-tooltip
            category="tertiary"
            icon="copy-to-clipboard"
            class="gl-my-n3 gl-ml-2"
            :title="__('Copy key')"
            :data-clipboard-text="item.key"
            :aria-label="__('Copy to clipboard')"
          />
        </div>
      </template>
      <template #cell(value)="{ item }">
        <div
          class="gl-display-flex gl-align-items-flex-start gl-justify-content-end gl-lg-justify-content-start gl-mr-n3"
        >
          <span v-if="valuesHidden">*****</span>
          <span
            v-else
            :id="`ci-variable-value-${item.id}`"
            class="gl-display-inline-block gl-max-w-full gl-text-truncate"
            >{{ item.value }}</span
          >
          <gl-button
            v-gl-tooltip
            category="tertiary"
            icon="copy-to-clipboard"
            class="gl-my-n3 gl-ml-2"
            :title="__('Copy value')"
            :data-clipboard-text="item.value"
            :aria-label="__('Copy to clipboard')"
          />
        </div>
      </template>
      <template #cell(options)="{ item }">
        <span>{{ item.options }}</span>
      </template>
      <template #cell(environment_scope)="{ item }">
        <div
          class="gl-display-flex gl-align-items-flex-start gl-justify-content-end gl-lg-justify-content-start gl-mr-n3"
        >
          <span
            :id="`ci-variable-env-${item.id}`"
            class="gl-display-inline-block gl-max-w-full gl-word-break-word"
            >{{ item.environment_scope }}</span
          >
          <gl-button
            v-gl-tooltip
            category="tertiary"
            icon="copy-to-clipboard"
            class="gl-my-n3 gl-ml-2"
            :title="__('Copy environment')"
            :data-clipboard-text="item.environment_scope"
            :aria-label="__('Copy to clipboard')"
          />
        </div>
      </template>
      <template #cell(actions)="{ item }">
        <gl-button
          v-gl-modal-directive="$options.modalId"
          icon="pencil"
          :aria-label="__('Edit')"
          data-qa-selector="edit_ci_variable_button"
          @click="editVariableClicked(item.index)"
        />
      </template>
      <template #empty>
        <p class="gl-text-center gl-py-6 gl-text-black-normal gl-mb-0">
          {{ __('There are no variables yet.') }}
        </p>
      </template>
    </gl-table>
    <div class="ci-variable-actions gl-display-flex gl-mt-5">
      <gl-button
        v-gl-modal-directive="$options.modalId"
        class="gl-mr-3"
        data-qa-selector="add_ci_variable_button"
        variant="confirm"
        category="primary"
        >{{ __('Add variable') }}</gl-button
      >
      <gl-button
        v-if="!isTableEmpty"
        data-qa-selector="reveal_ci_variable_value_button"
        @click="toggleValues(!valuesHidden)"
        >{{ valuesButtonText }}</gl-button
      >
    </div>
  </div>
</template>
