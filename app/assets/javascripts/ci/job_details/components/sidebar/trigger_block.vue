<script>
import { GlButton, GlTableLite } from '@gitlab/ui';
import { __ } from '~/locale';

const DEFAULT_TD_CLASSES = '!gl-text-sm';

export default {
  fields: [
    {
      key: 'key',
      label: __('Key'),
      tdAttr: { 'data-testid': 'trigger-build-key' },
      tdClass: DEFAULT_TD_CLASSES,
    },
    {
      key: 'value',
      label: __('Value'),
      tdAttr: { 'data-testid': 'trigger-build-value' },
      tdClass: DEFAULT_TD_CLASSES,
    },
  ],
  components: {
    GlButton,
    GlTableLite,
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
      <span class="gl-font-bold">{{ __('Trigger token:') }}</span> {{ trigger.short_token }}
    </p>

    <template v-if="hasVariables">
      <p class="gl-flex gl-items-center gl-justify-between">
        <span class="gl-flex gl-font-bold">{{ __('Trigger variables') }}</span>

        <gl-button
          v-if="hasValues"
          class="gl-mt-2"
          size="small"
          data-testid="trigger-reveal-values-button"
          @click="toggleValues"
          >{{ getToggleButtonText }}</gl-button
        >
      </p>

      <gl-table-lite :items="trigger.variables" :fields="$options.fields" small bordered fixed>
        <template #cell(key)="{ item }">
          <span class="gl-hyphens-auto gl-break-words">{{ item.key }}</span>
        </template>

        <template #cell(value)="data">
          <span class="gl-hyphens-auto gl-break-words">{{ getDisplayValue(data.value) }}</span>
        </template>
      </gl-table-lite>
    </template>
  </div>
</template>
