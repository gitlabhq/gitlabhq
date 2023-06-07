<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { __ } from '~/locale';
import { subscriptionsDropdownOptions } from '../../constants';

export default {
  subscriptionsDropdownOptions,
  i18n: {
    defaultDropdownText: __('Select subscription'),
    headerText: __('Change subscription'),
    resetText: __('Reset'),
  },
  components: {
    GlCollapsibleListbox,
  },
  data() {
    return {
      selectedValue: undefined,
    };
  },
  computed: {
    dropdownText() {
      const selected = this.$options.subscriptionsDropdownOptions.find(
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
};
</script>
<template>
  <div>
    <input type="hidden" name="update[subscription_event]" :value="selectedValue" />
    <gl-collapsible-listbox
      v-model="selectedValue"
      block
      :header-text="$options.i18n.headerText"
      :reset-button-label="$options.i18n.resetText"
      :toggle-text="dropdownText"
      :items="$options.subscriptionsDropdownOptions"
      @reset="handleReset"
    />
  </div>
</template>
