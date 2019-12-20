<script>
import _ from 'underscore';

import { GlDropdown, GlDropdownDivider, GlDropdownItem } from '@gitlab/ui';

const isValidItem = item =>
  _.isString(item.eventName) && _.isString(item.title) && _.isString(item.description);

export default {
  components: {
    GlDropdown,
    GlDropdownDivider,
    GlDropdownItem,
  },

  props: {
    actionItems: {
      type: Array,
      required: true,
      validator(value) {
        return value.length > 1 && value.every(isValidItem);
      },
    },
    menuClass: {
      type: String,
      required: false,
      default: '',
    },
    variant: {
      type: String,
      required: false,
      default: 'secondary',
    },
  },

  data() {
    return {
      selectedItem: this.actionItems[0],
    };
  },

  computed: {
    dropdownToggleText() {
      return this.selectedItem.title;
    },
  },

  methods: {
    triggerEvent() {
      this.$emit(this.selectedItem.eventName);
    },
  },
};
</script>

<template>
  <gl-dropdown
    :menu-class="`dropdown-menu-selectable ${menuClass}`"
    split
    :text="dropdownToggleText"
    :variant="variant"
    v-bind="$attrs"
    @click="triggerEvent"
  >
    <template v-for="(item, itemIndex) in actionItems">
      <gl-dropdown-item
        :key="item.eventName"
        :active="selectedItem === item"
        active-class="is-active"
        @click="selectedItem = item"
      >
        <strong>{{ item.title }}</strong>
        <div>{{ item.description }}</div>
      </gl-dropdown-item>

      <gl-dropdown-divider
        v-if="itemIndex < actionItems.length - 1"
        :key="`${item.eventName}-divider`"
      />
    </template>
  </gl-dropdown>
</template>
