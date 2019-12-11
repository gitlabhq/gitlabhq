<script>
import { GlButton } from '@gitlab/ui';
import { __ } from '~/locale';

const HIDDEN_VALUE = '••••••';

export default {
  components: {
    GlButton,
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
      return this.trigger.variables && this.trigger.variables.length > 0;
    },
    getToggleButtonText() {
      return this.showVariableValues ? __('Hide values') : __('Reveal values');
    },
    hasValues() {
      return this.trigger.variables.some(v => v.value);
    },
  },
  methods: {
    toggleValues() {
      this.showVariableValues = !this.showVariableValues;
    },
    getDisplayValue(value) {
      return this.showVariableValues ? value : HIDDEN_VALUE;
    },
  },
};
</script>

<template>
  <div class="build-widget block">
    <p
      v-if="trigger.short_token"
      class="js-short-token"
      :class="{ 'append-bottom-5': hasVariables, 'append-bottom-0': !hasVariables }"
    >
      <span class="font-weight-bold">{{ __('Trigger token:') }}</span> {{ trigger.short_token }}
    </p>

    <template v-if="hasVariables">
      <p class="trigger-variables-btn-container d-flex">
        <span class="font-weight-bold">{{ __('Trigger variables:') }}</span>

        <gl-button
          v-if="hasValues"
          class="btn-sm group js-reveal-variables trigger-variables-btn"
          @click="toggleValues"
          >{{ getToggleButtonText }}</gl-button
        >
      </p>

      <table class="js-build-variables trigger-build-variables">
        <tr v-for="(variable, index) in trigger.variables" :key="`${variable.key}-${index}`">
          <td class="js-build-variable trigger-build-variable trigger-variables-table-cell">
            {{ variable.key }}
          </td>
          <td class="js-build-value trigger-build-value trigger-variables-table-cell">
            {{ getDisplayValue(variable.value) }}
          </td>
        </tr>
      </table>
    </template>
  </div>
</template>
