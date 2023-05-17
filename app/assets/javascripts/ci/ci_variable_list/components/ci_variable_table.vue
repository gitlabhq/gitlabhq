<script>
import {
  GlAlert,
  GlButton,
  GlLoadingIcon,
  GlModalDirective,
  GlKeysetPagination,
  GlTable,
  GlTooltipDirective,
} from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import {
  ADD_CI_VARIABLE_MODAL_ID,
  DEFAULT_EXCEEDS_VARIABLE_LIMIT_TEXT,
  EXCEEDS_VARIABLE_LIMIT_TEXT,
  MAXIMUM_VARIABLE_LIMIT_REACHED,
  variableText,
} from '../constants';
import { convertEnvironmentScope } from '../utils';

export default {
  modalId: ADD_CI_VARIABLE_MODAL_ID,
  fields: [
    {
      key: 'variableType',
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
      key: 'environmentScope',
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
    GlAlert,
    GlButton,
    GlKeysetPagination,
    GlLoadingIcon,
    GlTable,
  },
  directives: {
    GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    entity: {
      type: String,
      required: false,
      default: '',
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
    maxVariableLimit: {
      type: Number,
      required: true,
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
      areValuesHidden: true,
    };
  },
  computed: {
    exceedsVariableLimit() {
      return this.maxVariableLimit > 0 && this.variables.length >= this.maxVariableLimit;
    },
    exceedsVariableLimitText() {
      if (this.exceedsVariableLimit && this.entity) {
        return sprintf(EXCEEDS_VARIABLE_LIMIT_TEXT, {
          entity: this.entity,
          currentVariableCount: this.variables.length,
          maxVariableLimit: this.maxVariableLimit,
        });
      }

      return DEFAULT_EXCEEDS_VARIABLE_LIMIT_TEXT;
    },
    showAlert() {
      return !this.isLoading && this.exceedsVariableLimit;
    },
    valuesButtonText() {
      return this.areValuesHidden ? __('Reveal values') : __('Hide values');
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
    setSelectedVariable(index = -1) {
      this.$emit('set-selected-variable', this.variables[index] ?? null);
    },
    getOptions(item) {
      const options = [];
      if (item.protected) {
        options.push(s__('CiVariables|Protected'));
      }
      if (item.masked) {
        options.push(s__('CiVariables|Masked'));
      }
      if (!item.raw) {
        options.push(s__('CiVariables|Expanded'));
      }
      return options.join(', ');
    },
  },
  maximumVariableLimitReached: MAXIMUM_VARIABLE_LIMIT_REACHED,
};
</script>

<template>
  <div class="ci-variable-table" data-testid="ci-variable-table">
    <gl-loading-icon v-if="isLoading" />
    <gl-alert
      v-if="showAlert"
      :dismissible="false"
      :title="$options.maximumVariableLimitReached"
      variant="info"
    >
      {{ exceedsVariableLimitText }}
    </gl-alert>
    <div
      v-if="glFeatures.ciVariablesPages"
      class="ci-variable-actions gl-display-flex gl-justify-content-end gl-my-3"
    >
      <gl-button v-if="!isTableEmpty" @click="toggleHiddenState">{{ valuesButtonText }}</gl-button>
      <gl-button
        v-gl-modal-directive="$options.modalId"
        class="gl-mx-3"
        data-qa-selector="add_ci_variable_button"
        variant="confirm"
        category="primary"
        :aria-label="__('Add')"
        :disabled="exceedsVariableLimit"
        @click="setSelectedVariable()"
        >{{ __('Add variable') }}</gl-button
      >
    </div>
    <gl-table
      v-if="!isLoading"
      :fields="fields"
      :items="variablesWithOptions"
      tbody-tr-class="js-ci-variable-row"
      data-qa-selector="ci_variable_table_content"
      sort-by="key"
      sort-direction="asc"
      stacked="lg"
      table-class="gl-border-t"
      fixed
      show-empty
      sort-icon-left
      no-sort-reset
      no-local-sorting
      @sort-changed="(val) => $emit('sort-changed', val)"
    >
      <template #table-colgroup="scope">
        <col v-for="field in scope.fields" :key="field.key" :style="field.customStyle" />
      </template>
      <template #cell(variableType)="{ item }">
        {{ generateTypeText(item) }}
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
          <span v-if="areValuesHidden" data-testid="hiddenValue">*****</span>
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
            class="gl-my-n3 gl-ml-2"
            :title="__('Copy value')"
            :data-clipboard-text="item.value"
            :aria-label="__('Copy to clipboard')"
          />
        </div>
      </template>
      <template #cell(options)="{ item }">
        <span data-testid="ci-variable-table-row-options">{{ item.options }}</span>
      </template>
      <template #cell(environmentScope)="{ item }">
        <div
          class="gl-display-flex gl-align-items-flex-start gl-justify-content-end gl-lg-justify-content-start gl-mr-n3"
        >
          <span
            :id="`ci-variable-env-${item.id}`"
            class="gl-display-inline-block gl-max-w-full gl-word-break-word"
            >{{ convertEnvironmentScopeValue(item.environmentScope) }}</span
          >
          <gl-button
            v-gl-tooltip
            category="tertiary"
            icon="copy-to-clipboard"
            class="gl-my-n3 gl-ml-2"
            :title="__('Copy environment')"
            :data-clipboard-text="convertEnvironmentScopeValue(item.environmentScope)"
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
          @click="setSelectedVariable(item.index)"
        />
      </template>
      <template #empty>
        <p class="gl-text-center gl-py-6 gl-text-black-normal gl-mb-0">
          {{ __('There are no variables yet.') }}
        </p>
      </template>
    </gl-table>
    <gl-alert
      v-if="showAlert"
      :dismissible="false"
      :title="$options.maximumVariableLimitReached"
      variant="info"
    >
      {{ exceedsVariableLimitText }}
    </gl-alert>
    <div v-if="!glFeatures.ciVariablesPages" class="ci-variable-actions gl-display-flex gl-mt-5">
      <gl-button
        v-gl-modal-directive="$options.modalId"
        class="gl-mr-3"
        data-qa-selector="add_ci_variable_button"
        variant="confirm"
        category="primary"
        :aria-label="__('Add')"
        :disabled="exceedsVariableLimit"
        @click="setSelectedVariable()"
        >{{ __('Add variable') }}</gl-button
      >
      <gl-button v-if="!isTableEmpty" @click="toggleHiddenState">{{ valuesButtonText }}</gl-button>
    </div>
    <div v-else class="gl-display-flex gl-justify-content-center gl-mt-6">
      <gl-keyset-pagination
        v-bind="pageInfo"
        :prev-text="__('Previous')"
        :next-text="__('Next')"
        @prev="$emit('handle-prev-page')"
        @next="$emit('handle-next-page')"
      />
    </div>
  </div>
</template>
