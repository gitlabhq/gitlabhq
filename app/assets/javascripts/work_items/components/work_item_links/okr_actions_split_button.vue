<script>
import { GlDropdown, GlDropdownSectionHeader, GlDropdownItem, GlDropdownDivider } from '@gitlab/ui';

import { s__ } from '~/locale';

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
    GlDropdown,
    GlDropdownSectionHeader,
    GlDropdownItem,
    GlDropdownDivider,
  },
  methods: {
    change({ eventName }) {
      this.$emit(eventName);
    },
  },
};
</script>

<template>
  <gl-dropdown :text="__('Add')" size="small" right>
    <gl-dropdown-section-header>{{ __('Objective') }}</gl-dropdown-section-header>
    <gl-dropdown-item
      v-for="item in $options.objectiveActionItems"
      :key="item.eventName"
      @click="change(item)"
    >
      {{ item.title }}
    </gl-dropdown-item>

    <gl-dropdown-divider />
    <gl-dropdown-section-header>{{ __('Key result') }}</gl-dropdown-section-header>
    <gl-dropdown-item
      v-for="item in $options.keyResultActionItems"
      :key="item.eventName"
      @click="change(item)"
    >
      {{ item.title }}
    </gl-dropdown-item>
  </gl-dropdown>
</template>
