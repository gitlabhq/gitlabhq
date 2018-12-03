<script>
import { GlButton } from '@gitlab/ui';

const HIDDEN_VALUE = '••••••';
const TOGGLE_BUTTON_TEXT = {
  HIDE: 'Hide',
  REVEAL: 'Reveal',
};

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
      return Array.isArray(this.trigger.variables) && this.trigger.variables.length > 0;
    },
    getToggleButtonText() {
      const { HIDE, REVEAL } = TOGGLE_BUTTON_TEXT;
      return `${this.showVariableValues ? HIDE : REVEAL} Values`;
    },
    hasValues() {
      return (this.trigger.variables || []).some(v => v.value);
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
    <h4 class="title">{{ __('Trigger') }}</h4>

    <p
      v-if="trigger.short_token"
      class="js-short-token"
      :class="{ 'append-bottom-0': !hasVariables }"
    >
      <span class="build-light-text"> {{ __('Token') }} </span> {{ trigger.short_token }}
    </p>

    <template v-if="hasVariables">
      <p class="trigger-variables-btn-container">
        <span class="build-light-text"> {{ __('Variables:') }} </span>

        <gl-button
          v-if="hasValues"
          type="button"
          class="btn btn-default group js-reveal-variables"
          @click="toggleValues"
        >
          {{ __(getToggleButtonText) }}
        </gl-button>
      </p>

      <table class="js-build-variables trigger-variables-table trigger-build-variables">
        <tr v-for="variable in trigger.variables">
          <td
            v-bind:key="`${variable.key}-variable`"
            class="js-build-variable trigger-build-variable"
          >
            {{ variable.key }}
          </td>
          <td v-bind:key="`${variable.key}-value`" class="js-build-value trigger-build-value">
            {{ getDisplayValue(variable.value) }}
          </td>
        </tr>
      </table>
    </template>
  </div>
</template>
