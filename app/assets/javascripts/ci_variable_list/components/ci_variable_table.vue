<script>
import { GlTable, GlButton, GlModalDirective, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import { s__, __ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';
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
    CiVariablePopover,
    GlButton,
    GlIcon,
    GlTable,
    TooltipOnTruncate,
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
        <div class="gl-display-flex gl-align-items-center">
          <tooltip-on-truncate :title="item.key" truncate-target="child">
            <span
              :id="`ci-variable-key-${item.id}`"
              class="gl-display-inline-block gl-max-w-full gl-text-truncate"
              >{{ item.key }}</span
            >
          </tooltip-on-truncate>
          <gl-button
            v-gl-tooltip
            category="tertiary"
            icon="copy-to-clipboard"
            :title="__('Copy key')"
            :data-clipboard-text="item.key"
            :aria-label="__('Copy to clipboard')"
          />
        </div>
      </template>
      <template #cell(value)="{ item }">
        <div class="gl-display-flex gl-align-items-center">
          <span v-if="valuesHidden">*********************</span>
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
            :title="__('Copy value')"
            :data-clipboard-text="item.value"
            :aria-label="__('Copy to clipboard')"
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
        <div class="gl-display-flex">
          <span
            :id="`ci-variable-env-${item.id}`"
            class="gl-display-inline-block gl-max-w-full gl-text-truncate"
            >{{ item.environment_scope }}</span
          >
          <ci-variable-popover
            :target="`ci-variable-env-${item.id}`"
            :value="item.environment_scope"
            :tooltip-text="__('Copy environment')"
          />
        </div>
      </template>
      <template #cell(actions)="{ item }">
        <gl-button
          v-gl-modal-directive="$options.modalId"
          icon="pencil"
          :aria-label="__('Edit')"
          data-qa-selector="edit_ci_variable_button"
          @click="editVariable(item)"
        />
      </template>
      <template #empty>
        <p class="gl-text-center gl-py-6 gl-text-black-normal gl-mb-0">
          {{ __('There are no variables yet.') }}
        </p>
      </template>
    </gl-table>
    <div
      class="ci-variable-actions gl-display-flex"
      :class="{ 'gl-justify-content-center': isTableEmpty }"
    >
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
