<script>
import {
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlDisclosureDropdownGroup,
} from '@gitlab/ui';
import {
  ORDERED_GENERAL_ACTIONS,
  ORDERED_DANGER_ACTIONS,
  DEFAULT_ACTION_ITEM_DEFINITIONS,
  ACTION_EDIT,
  ACTION_ARCHIVE,
  ACTION_UNARCHIVE,
  ACTION_LEAVE,
  ACTION_RESTORE,
  ACTION_DELETE,
  ACTION_DELETE_IMMEDIATELY,
} from './constants';

export default {
  name: 'ListActions',
  ACTION_EDIT,
  ACTION_ARCHIVE,
  ACTION_UNARCHIVE,
  ACTION_LEAVE,
  ACTION_RESTORE,
  ACTION_DELETE,
  ACTION_DELETE_IMMEDIATELY,
  components: {
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlDisclosureDropdownGroup,
  },
  props: {
    actions: {
      type: Object,
      required: true,
    },
    availableActions: {
      type: Array,
      required: true,
    },
  },
  computed: {
    generalActions() {
      return ORDERED_GENERAL_ACTIONS.filter(
        (action) => this.availableActions.includes(action) && this.actionItem(action),
      );
    },
    dangerActions() {
      return ORDERED_DANGER_ACTIONS.filter(
        (action) => this.availableActions.includes(action) && this.actionItem(action),
      );
    },
    hasDangerActions() {
      return this.dangerActions.length;
    },
    customActions() {
      const baseActionKeys = Object.keys(DEFAULT_ACTION_ITEM_DEFINITIONS);

      return Object.entries(this.actions).reduce((accumulator, [key, value]) => {
        if (baseActionKeys.includes(key)) {
          return accumulator;
        }

        return {
          ...accumulator,
          [key]: value,
        };
      }, {});
    },
  },
  methods: {
    actionItem(action) {
      return {
        ...DEFAULT_ACTION_ITEM_DEFINITIONS[action],
        ...this.actions[action],
      };
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    icon="ellipsis_v"
    no-caret
    :toggle-text="__('Actions')"
    text-sr-only
    placement="bottom-end"
    category="tertiary"
  >
    <!-- General actions -->
    <gl-disclosure-dropdown-item
      v-for="action in generalActions"
      :key="action"
      :item="actionItem(action)"
    />

    <gl-disclosure-dropdown-item
      v-for="(customAction, actionKey) in customActions"
      :key="actionKey"
      :item="customAction"
    />

    <!-- Danger actions -->
    <gl-disclosure-dropdown-group v-if="hasDangerActions" bordered>
      <gl-disclosure-dropdown-item
        v-for="action in dangerActions"
        :key="action"
        :item="actionItem(action)"
      />
    </gl-disclosure-dropdown-group>
  </gl-disclosure-dropdown>
</template>
