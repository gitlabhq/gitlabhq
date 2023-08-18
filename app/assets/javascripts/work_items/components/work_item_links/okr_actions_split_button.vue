<script>
import { GlDisclosureDropdown } from '@gitlab/ui';

import { s__, __ } from '~/locale';

const objectiveActionItems = [
  {
    title: s__('OKR|New objective'),
    eventName: 'showCreateObjectiveForm',
  },
  {
    title: s__('OKR|Existing objective'),
    eventName: 'showAddObjectiveForm',
  },
];

const keyResultActionItems = [
  {
    title: s__('OKR|New key result'),
    eventName: 'showCreateKeyResultForm',
  },
  {
    title: s__('OKR|Existing key result'),
    eventName: 'showAddKeyResultForm',
  },
];

export default {
  keyResultActionItems,
  objectiveActionItems,
  components: {
    GlDisclosureDropdown,
  },
  computed: {
    objectiveDropdownItems() {
      return {
        name: __('Objective'),
        items: this.$options.objectiveActionItems.map((item) => ({
          text: item.title,
          action: () => this.change(item),
        })),
      };
    },
    keyResultDropdownItems() {
      return {
        name: __('Key result'),
        items: this.$options.keyResultActionItems.map((item) => ({
          text: item.title,
          action: () => this.change(item),
        })),
      };
    },
    dropdownItems() {
      return [this.objectiveDropdownItems, this.keyResultDropdownItems];
    },
  },
  methods: {
    change({ eventName }) {
      this.$emit(eventName);
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    :toggle-text="__('Add')"
    size="small"
    placement="right"
    :items="dropdownItems"
  />
</template>
