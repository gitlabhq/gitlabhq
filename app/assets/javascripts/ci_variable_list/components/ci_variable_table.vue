<script>
import { GlTable, GlButton, GlModalDirective, GlIcon } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import { s__, __ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { ADD_CI_VARIABLE_MODAL_ID } from '../constants';
import CiVariablePopover from './ci_variable_popover.vue';

export default {
  modalId: ADD_CI_VARIABLE_MODAL_ID,
  trueIcon: 'mobile-issue-close',
  falseIcon: 'close',
  iconSize: 16,
  fields: [
    {
      key: 'variable_type',
      label: s__('CiVariables|Type'),
      customStyle: { width: '70px' },
    },
    {
      key: 'key',
      label: s__('CiVariables|Key'),
      tdClass: 'text-plain',
      sortable: true,
      customStyle: { width: '40%' },
    },
    {
      key: 'value',
      label: s__('CiVariables|Value'),
      customStyle: { width: '40%' },
    },
    {
      key: 'protected',
      label: s__('CiVariables|Protected'),
      customStyle: { width: '100px' },
    },
    {
      key: 'masked',
      label: s__('CiVariables|Masked'),
      customStyle: { width: '100px' },
    },
    {
      key: 'environment_scope',
      label: s__('CiVariables|Environments'),
      customStyle: { width: '20%' },
    },
    {
      key: 'actions',
      label: '',
      tdClass: 'text-right',
      customStyle: { width: '35px' },
    },
  ],
  components: {
    GlTable,
    GlButton,
    GlIcon,
    CiVariablePopover,
  },
  directives: {
    GlModalDirective,
  },
  mixins: [glFeatureFlagsMixin()],
  computed: {
    ...mapState(['variables', 'valuesHidden', 'isLoading', 'isDeleting']),
    valuesButtonText() {
      return this.valuesHidden ? __('Reveal values') : __('Hide values');
    },
    tableIsNotEmpty() {
      return this.variables && this.variables.length > 0;
    },
    fields() {
      return this.$options.fields;
    },
  },
  mounted() {
    this.fetchVariables();
  },
  methods: {
    ...mapActions(['fetchVariables', 'toggleValues', 'editVariable']),
  },
};
</script>

<template>
  <div class="ci-variable-table" data-testid="ci-variable-table">
    <gl-table
      :fields="fields"
      :items="variables"
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
        <div class="d-flex truncated-container">
          <span :id="`ci-variable-key-${item.id}`" class="d-inline-block mw-100 text-truncate">{{
            item.key
          }}</span>
          <ci-variable-popover
            :target="`ci-variable-key-${item.id}`"
            :value="item.key"
            :tooltip-text="__('Copy key')"
          />
        </div>
      </template>
      <template #cell(value)="{ item }">
        <span v-if="valuesHidden">*********************</span>
        <div v-else class="d-flex truncated-container">
          <span :id="`ci-variable-value-${item.id}`" class="d-inline-block mw-100 text-truncate">{{
            item.value
          }}</span>
          <ci-variable-popover
            :target="`ci-variable-value-${item.id}`"
            :value="item.value"
            :tooltip-text="__('Copy value')"
          />
        </div>
      </template>
      <template #cell(protected)="{ item }">
        <gl-icon v-if="item.protected" :size="$options.iconSize" :name="$options.trueIcon" />
        <gl-icon v-else :size="$options.iconSize" :name="$options.falseIcon" />
      </template>
      <template #cell(masked)="{ item }">
        <gl-icon v-if="item.masked" :size="$options.iconSize" :name="$options.trueIcon" />
        <gl-icon v-else :size="$options.iconSize" :name="$options.falseIcon" />
      </template>
      <template #cell(environment_scope)="{ item }">
        <div class="d-flex truncated-container">
          <span :id="`ci-variable-env-${item.id}`" class="d-inline-block mw-100 text-truncate">{{
            item.environment_scope
          }}</span>
          <ci-variable-popover
            :target="`ci-variable-env-${item.id}`"
            :value="item.environment_scope"
            :tooltip-text="__('Copy environment')"
          />
        </div>
      </template>
      <template #cell(actions)="{ item }">
        <gl-button
          ref="edit-ci-variable"
          v-gl-modal-directive="$options.modalId"
          icon="pencil"
          :aria-label="__('Edit')"
          data-qa-selector="edit_ci_variable_button"
          @click="editVariable(item)"
        />
      </template>
      <template #empty>
        <p ref="empty-variables" class="text-center empty-variables text-plain">
          {{ __('There are no variables yet.') }}
        </p>
      </template>
    </gl-table>
    <div
      class="ci-variable-actions gl-display-flex"
      :class="{ 'justify-content-center': !tableIsNotEmpty }"
    >
      <gl-button
        ref="add-ci-variable"
        v-gl-modal-directive="$options.modalId"
        class="gl-mr-3"
        data-qa-selector="add_ci_variable_button"
        variant="confirm"
        category="primary"
        >{{ __('Add variable') }}</gl-button
      >
      <gl-button
        v-if="tableIsNotEmpty"
        ref="secret-value-reveal-button"
        data-qa-selector="reveal_ci_variable_value_button"
        @click="toggleValues(!valuesHidden)"
        >{{ valuesButtonText }}</gl-button
      >
    </div>
  </div>
</template>
