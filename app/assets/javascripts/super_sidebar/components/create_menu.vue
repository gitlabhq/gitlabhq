<script>
import { GlDisclosureDropdown, GlTooltip } from '@gitlab/ui';
import { __ } from '~/locale';

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
  toggleId: 'create-menu-toggle',
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
      data-qa-selector="new_menu_toggle"
    />
    <gl-tooltip :target="`#${$options.toggleId}`" placement="bottom" container="#super-sidebar">
      {{ $options.i18n.createNew }}
    </gl-tooltip>
  </div>
</template>
