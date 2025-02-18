<script>
import { GlDisclosureDropdown, GlDisclosureDropdownItem, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';

export const i18n = {
  dropdownLabel: __('Actions'),
  compare: __('Compare'),
};

export default {
  i18n,
  components: {
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
  },
  directives: {
    GlTooltipDirective,
  },
  inject: ['comparePath'],
  computed: {
    compareItem() {
      return {
        text: i18n.compare,
        href: this.comparePath,
        extraAttrs: {
          'data-testid': 'tree-compare-control',
          rel: 'nofollow',
        },
      };
    },
  },
};
</script>
<template>
  <gl-disclosure-dropdown
    v-gl-tooltip-directive="$options.i18n.dropdownLabel"
    no-caret
    icon="ellipsis_v"
    data-testid="default-actions-container"
    placement="bottom-end"
    category="tertiary"
    :toggle-text="$options.i18n.dropdownLabel"
    text-sr-only
  >
    <gl-disclosure-dropdown-item v-if="comparePath" :item="compareItem" class="shortcuts-compare" />
  </gl-disclosure-dropdown>
</template>
