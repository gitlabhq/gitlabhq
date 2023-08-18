<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlCollapsibleListbox,
  },
  data() {
    return {
      value: null,
    };
  },
  i18n: {
    defaultDropdownText: __('Select confidentiality'),
    headerText: __('Change confidentiality'),
    resetText: __('Reset'),
  },
  computed: {
    toggleText() {
      return this.value ? null : this.$options.i18n.defaultDropdownText;
    },
  },
  methods: {
    handleReset() {
      this.value = null;
    },
  },
  dropdownOptions: [
    {
      text: __('Confidential'),
      value: 'true',
    },
    {
      text: __('Not confidential'),
      value: 'false',
    },
  ],
};
</script>

<template>
  <div>
    <input type="hidden" name="update[confidentiality]" :value="value" />
    <gl-collapsible-listbox
      v-model="value"
      block
      :header-text="$options.i18n.headerText"
      :reset-button-label="$options.i18n.resetText"
      :toggle-text="toggleText"
      :items="$options.dropdownOptions"
      @reset="handleReset"
    />
  </div>
</template>
