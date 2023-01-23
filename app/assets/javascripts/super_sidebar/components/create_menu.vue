<script>
import { GlDisclosureDropdown, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlDisclosureDropdown,
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
};
</script>

<template>
  <gl-disclosure-dropdown
    v-gl-tooltip:super-sidebar.bottom="$options.i18n.createNew"
    category="tertiary"
    icon="plus"
    :items="groups"
    no-caret
    text-sr-only
    :toggle-text="$options.i18n.createNew"
  />
</template>
