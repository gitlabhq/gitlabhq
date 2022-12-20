<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { __ } from '~/locale';
import { subscriptionsDropdownOptions } from '../../constants';

export default {
  subscriptionsDropdownOptions,
  i18n: {
    defaultDropdownText: __('Select subscription'),
    headerText: __('Change subscription'),
  },
  components: {
    GlDropdown,
    GlDropdownItem,
  },
  data() {
    return {
      subscription: undefined,
    };
  },
  computed: {
    dropdownText() {
      return this.subscription?.text ?? this.$options.i18n.defaultDropdownText;
    },
    selectedValue() {
      return this.subscription?.value;
    },
  },
  methods: {
    handleClick(option) {
      this.subscription = option.value === this.subscription?.value ? undefined : option;
    },
  },
};
</script>
<template>
  <div>
    <input type="hidden" name="update[subscription_event]" :value="selectedValue" />
    <gl-dropdown class="gl-w-full" :header-text="$options.i18n.headerText" :text="dropdownText">
      <gl-dropdown-item
        v-for="subscriptionsOption in $options.subscriptionsDropdownOptions"
        :key="subscriptionsOption.value"
        is-check-item
        :is-checked="selectedValue === subscriptionsOption.value"
        @click="handleClick(subscriptionsOption)"
      >
        {{ subscriptionsOption.text }}
      </gl-dropdown-item>
    </gl-dropdown>
  </div>
</template>
