<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { __ } from '~/locale';
import { ISSUE_STATUS_SELECT_OPTIONS } from '../constants';

export default {
  name: 'StatusSelect',
  components: {
    GlDropdown,
    GlDropdownItem,
  },
  data() {
    return {
      status: null,
    };
  },
  computed: {
    dropdownText() {
      return this.status?.text ?? this.$options.i18n.defaultDropdownText;
    },
    selectedValue() {
      return this.status?.value;
    },
  },
  methods: {
    onDropdownItemClick(statusOption) {
      // clear status if the currently checked status is clicked again
      if (this.status?.value === statusOption.value) {
        this.status = null;
      } else {
        this.status = statusOption;
      }
    },
  },
  i18n: {
    dropdownTitle: __('Change status'),
    defaultDropdownText: __('Select status'),
  },
  ISSUE_STATUS_SELECT_OPTIONS,
};
</script>
<template>
  <div>
    <input type="hidden" name="update[state_event]" :value="selectedValue" />
    <gl-dropdown :text="dropdownText" :title="$options.i18n.dropdownTitle" class="gl-w-full">
      <gl-dropdown-item
        v-for="statusOption in $options.ISSUE_STATUS_SELECT_OPTIONS"
        :key="statusOption.value"
        :is-checked="selectedValue === statusOption.value"
        is-check-item
        :title="statusOption.text"
        @click="onDropdownItemClick(statusOption)"
      >
        {{ statusOption.text }}
      </gl-dropdown-item>
    </gl-dropdown>
  </div>
</template>
