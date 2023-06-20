<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { __ } from '~/locale';
import { statusDropdownOptions } from '../../constants';

export default {
  components: {
    GlCollapsibleListbox,
  },
  data() {
    return {
      status: null,
      selectedValue: undefined,
    };
  },
  computed: {
    dropdownText() {
      const selected = this.$options.statusDropdownOptions.find(
        (option) => option.value === this.selectedValue,
      );
      return selected?.text || this.$options.i18n.defaultDropdownText;
    },
  },
  methods: {
    handleReset() {
      this.selectedValue = undefined;
    },
  },
  i18n: {
    dropdownTitle: __('Change status'),
    defaultDropdownText: __('Select status'),
    resetText: __('Reset'),
  },
  statusDropdownOptions,
};
</script>
<template>
  <div>
    <input type="hidden" name="update[state_event]" :value="selectedValue" />
    <gl-collapsible-listbox
      v-model="selectedValue"
      block
      :header-text="$options.i18n.dropdownTitle"
      :reset-button-label="$options.i18n.resetText"
      :toggle-text="dropdownText"
      :items="$options.statusDropdownOptions"
      @reset="handleReset"
    />
  </div>
</template>
