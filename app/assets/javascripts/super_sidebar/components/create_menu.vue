<script>
import { GlDisclosureDropdown, GlTooltip } from '@gitlab/ui';
import { __ } from '~/locale';
import { DROPDOWN_Y_OFFSET } from '../constants';

// Left offset required for the dropdown to be aligned with the super sidebar
const DROPDOWN_X_OFFSET = -147;

export default {
  components: {
    GlDisclosureDropdown,
    GlTooltip,
  },
  i18n: {
    createNew: __('Create new...'),
  },
  props: {
    groups: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      dropdownOpen: false,
    };
  },
  toggleId: 'create-menu-toggle',
  popperOptions: {
    modifiers: [
      {
        name: 'offset',
        options: {
          offset: [DROPDOWN_X_OFFSET, DROPDOWN_Y_OFFSET],
        },
      },
    ],
  },
};
</script>

<template>
  <div>
    <gl-disclosure-dropdown
      category="tertiary"
      icon="plus"
      :items="groups"
      no-caret
      text-sr-only
      :toggle-text="$options.i18n.createNew"
      :toggle-id="$options.toggleId"
      :popper-options="$options.popperOptions"
      data-qa-selector="new_menu_toggle"
      @shown="dropdownOpen = true"
      @hidden="dropdownOpen = false"
    />
    <gl-tooltip
      v-if="!dropdownOpen"
      :target="`#${$options.toggleId}`"
      placement="bottom"
      container="#super-sidebar"
    >
      {{ $options.i18n.createNew }}
    </gl-tooltip>
  </div>
</template>
