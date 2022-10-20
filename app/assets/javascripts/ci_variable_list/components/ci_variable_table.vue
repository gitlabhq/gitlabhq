<script>
import {
  GlButton,
  GlIcon,
  GlLoadingIcon,
  GlModalDirective,
  GlTable,
  GlTooltipDirective,
} from '@gitlab/ui';
import { s__, __ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';
import { ADD_CI_VARIABLE_MODAL_ID, variableText } from '../constants';
import { convertEnvironmentScope } from '../utils';
import CiVariablePopover from './ci_variable_popover.vue';

export default {
  modalId: ADD_CI_VARIABLE_MODAL_ID,
  trueIcon: 'mobile-issue-close',
  falseIcon: 'close',
  iconSize: 16,
  fields: [
    {
      key: 'variableType',
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
      key: 'environmentScope',
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
    GlLoadingIcon,
    GlTable,
    TooltipOnTruncate,
  },
  directives: {
    GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    isLoading: {
      type: Boolean,
      required: true,
    },
    variables: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      areValuesHidden: true,
    };
  },
  computed: {
    valuesButtonText() {
      return this.areValuesHidden ? __('Reveal values') : __('Hide values');
    },
    isTableEmpty() {
      return !this.variables || this.variables.length === 0;
    },
    fields() {
      return this.$options.fields;
    },
  },
  methods: {
    convertEnvironmentScopeValue(env) {
      return convertEnvironmentScope(env);
    },
    generateTypeText(item) {
      return variableText[item.variableType];
    },
    toggleHiddenState() {
      this.areValuesHidden = !this.areValuesHidden;
    },
    setSelectedVariable(variable = null) {
      this.$emit('set-selected-variable', variable);
    },
  },
};
</script>

<template>
  <div class="ci-variable-table" data-testid="ci-variable-table">
    <gl-loading-icon v-if="isLoading" />
    <gl-table
      v-else
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
      <template #cell(variableType)="{ item }">
        <div class="gl-pt-2">
          {{ generateTypeText(item) }}
        </div>
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
          <span v-if="areValuesHidden" data-testid="hiddenValue">*********************</span>
          <span
            v-else
            :id="`ci-variable-value-${item.id}`"
            class="gl-display-inline-block gl-max-w-full gl-text-truncate"
            data-testid="revealedValue"
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
      <template #cell(environmentScope)="{ item }">
        <div class="gl-display-flex">
          <span
            :id="`ci-variable-env-${item.id}`"
            class="gl-display-inline-block gl-max-w-full gl-text-truncate"
            >{{ convertEnvironmentScopeValue(item.environmentScope) }}</span
          >
          <ci-variable-popover
            :target="`ci-variable-env-${item.id}`"
            :value="convertEnvironmentScopeValue(item.environmentScope)"
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
          @click="setSelectedVariable(item)"
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
        :aria-label="__('Add')"
        @click="setSelectedVariable()"
        >{{ __('Add variable') }}</gl-button
      >
      <gl-button
        v-if="!isTableEmpty"
        data-qa-selector="reveal_ci_variable_value_button"
        @click="toggleHiddenState"
        >{{ valuesButtonText }}</gl-button
      >
    </div>
  </div>
</template>
