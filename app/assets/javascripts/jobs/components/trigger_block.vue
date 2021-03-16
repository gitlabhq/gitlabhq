<script>
import { GlButton, GlTable } from '@gitlab/ui';
import { __ } from '~/locale';

const DEFAULT_TD_CLASSES = 'gl-w-half gl-font-sm! gl-border-gray-200!';
const DEFAULT_TH_CLASSES =
  'gl-bg-transparent! gl-border-b-solid! gl-border-b-gray-200! gl-border-b-1!';

export default {
  fields: [
    {
      key: 'key',
      label: __('Key'),
      tdAttr: { 'data-testid': 'trigger-build-key' },
      tdClass: DEFAULT_TD_CLASSES,
      thClass: DEFAULT_TH_CLASSES,
    },
    {
      key: 'value',
      label: __('Value'),
      tdAttr: { 'data-testid': 'trigger-build-value' },
      tdClass: DEFAULT_TD_CLASSES,
      thClass: DEFAULT_TH_CLASSES,
    },
  ],
  components: {
    GlButton,
    GlTable,
  },
  props: {
    trigger: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      showVariableValues: false,
    };
  },
  computed: {
    hasVariables() {
      return this.trigger.variables.length > 0;
    },
    getToggleButtonText() {
      return this.showVariableValues ? __('Hide values') : __('Reveal values');
    },
    hasValues() {
      return this.trigger.variables.some((v) => v.value);
    },
  },
  methods: {
    toggleValues() {
      this.showVariableValues = !this.showVariableValues;
    },
    getDisplayValue(value) {
      return this.showVariableValues ? value : '••••••';
    },
  },
};
</script>

<template>
  <div>
    <p
      v-if="trigger.short_token"
      :class="{ 'gl-mb-2': hasVariables, 'gl-mb-0': !hasVariables }"
      data-testid="trigger-short-token"
    >
      <span class="gl-font-weight-bold">{{ __('Trigger token:') }}</span> {{ trigger.short_token }}
    </p>

    <template v-if="hasVariables">
      <p class="gl-display-flex gl-justify-content-space-between gl-align-items-center">
        <span class="gl-font-weight-bold">{{ __('Trigger variables:') }}</span>

        <gl-button
          v-if="hasValues"
          class="gl-mt-2"
          size="small"
          data-testid="trigger-reveal-values-button"
          @click="toggleValues"
          >{{ getToggleButtonText }}</gl-button
        >
      </p>

      <gl-table :items="trigger.variables" :fields="$options.fields" small bordered>
        <template #cell(value)="data">
          {{ getDisplayValue(data.value) }}
        </template>
      </gl-table>
    </template>
  </div>
</template>
