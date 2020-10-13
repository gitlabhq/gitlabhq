<script>
import { isString } from 'lodash';
import { GlDropdown, GlDropdownDivider, GlDropdownItem } from '@gitlab/ui';

const isValidItem = item =>
  isString(item.eventName) && isString(item.title) && isString(item.description);

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
      default: 'default',
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
  <gl-dropdown
    :menu-class="menuClass"
    split
    :text="dropdownToggleText"
    :variant="variant"
    v-bind="$attrs"
    @click="triggerEvent"
  >
    <template v-for="(item, itemIndex) in actionItems">
      <gl-dropdown-item
        :key="item.eventName"
        :is-check-item="true"
        :is-checked="selectedItem === item"
        @click="changeSelectedItem(item)"
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
