<script>
import {
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlDisclosureDropdownGroup,
} from '@gitlab/ui';
import {
  DANGER_ACTIONS,
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
    hasDangerActions() {
      return this.availableActions.some((action) => DANGER_ACTIONS.includes(action));
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
    hasAction(action) {
      return this.availableActions.includes(action) && this.actionItem(action);
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
      v-if="hasAction($options.ACTION_EDIT)"
      :item="actionItem($options.ACTION_EDIT)"
    />

    <gl-disclosure-dropdown-item
      v-if="hasAction($options.ACTION_ARCHIVE)"
      :item="actionItem($options.ACTION_ARCHIVE)"
    />

    <gl-disclosure-dropdown-item
      v-if="hasAction($options.ACTION_UNARCHIVE)"
      :item="actionItem($options.ACTION_UNARCHIVE)"
    />

    <gl-disclosure-dropdown-item
      v-if="hasAction($options.ACTION_RESTORE)"
      :item="actionItem($options.ACTION_RESTORE)"
    />

    <gl-disclosure-dropdown-item
      v-for="(customAction, actionKey) in customActions"
      :key="actionKey"
      :item="customAction"
    />

    <!-- Danger actions -->
    <gl-disclosure-dropdown-group v-if="hasDangerActions" bordered>
      <gl-disclosure-dropdown-item
        v-if="hasAction($options.ACTION_LEAVE)"
        :item="actionItem($options.ACTION_LEAVE)"
      />

      <gl-disclosure-dropdown-item
        v-if="hasAction($options.ACTION_DELETE)"
        :item="actionItem($options.ACTION_DELETE)"
      />

      <gl-disclosure-dropdown-item
        v-if="hasAction($options.ACTION_DELETE_IMMEDIATELY)"
        :item="actionItem($options.ACTION_DELETE_IMMEDIATELY)"
      />
    </gl-disclosure-dropdown-group>
  </gl-disclosure-dropdown>
</template>
