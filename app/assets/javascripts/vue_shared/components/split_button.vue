<script>
import { isString } from 'lodash';
import {
  GlDeprecatedDropdown,
  GlDeprecatedDropdownDivider,
  GlDeprecatedDropdownItem,
} from '@gitlab/ui';

const isValidItem = item =>
  isString(item.eventName) && isString(item.title) && isString(item.description);

export default {
  components: {
    GlDeprecatedDropdown,
    GlDeprecatedDropdownDivider,
    GlDeprecatedDropdownItem,
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
    changeSelectedItem(item) {
      this.selectedItem = item;
      this.$emit('change', item);
    },
  },
};
</script>

<template>
  <gl-deprecated-dropdown
    :menu-class="`dropdown-menu-selectable ${menuClass}`"
    split
    :text="dropdownToggleText"
    :variant="variant"
    v-bind="$attrs"
    @click="triggerEvent"
  >
    <template v-for="(item, itemIndex) in actionItems">
      <gl-deprecated-dropdown-item
        :key="item.eventName"
        :active="selectedItem === item"
        active-class="is-active"
        @click="changeSelectedItem(item)"
      >
        <strong>{{ item.title }}</strong>
        <div>{{ item.description }}</div>
      </gl-deprecated-dropdown-item>

      <gl-deprecated-dropdown-divider
        v-if="itemIndex < actionItems.length - 1"
        :key="`${item.eventName}-divider`"
      />
    </template>
  </gl-deprecated-dropdown>
</template>
