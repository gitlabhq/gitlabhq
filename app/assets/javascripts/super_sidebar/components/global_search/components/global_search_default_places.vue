<script>
import { GlDisclosureDropdownGroup } from '@gitlab/ui';
import { PLACES } from '~/vue_shared/global_search/constants';
import { TRACKING_UNKNOWN_ID, TRACKING_UNKNOWN_PANEL } from '~/super_sidebar/constants';
import { TRACKING_CLICK_COMMAND_PALETTE_ITEM } from '../command_palette/constants';

export default {
  name: 'DefaultPlaces',
  i18n: {
    PLACES,
  },
  components: {
    GlDisclosureDropdownGroup,
  },
  inject: ['contextSwitcherLinks'],
  computed: {
    shouldRender() {
      return this.contextSwitcherLinks.length > 0;
    },
    group() {
      return {
        name: this.$options.i18n.PLACES,
        items: this.contextSwitcherLinks.map(({ title, link }) => ({
          text: title,
          href: link,
          extraAttrs: {
            'data-track-action': TRACKING_CLICK_COMMAND_PALETTE_ITEM,
            // The label and property are hard-coded as unknown for now for
            // parity with the existing corresponding context switcher items.
            // Once the context switcher is removed, these can be changed.
            'data-track-label': TRACKING_UNKNOWN_ID,
            'data-track-property': TRACKING_UNKNOWN_PANEL,
            'data-track-extra': JSON.stringify({ title }),
          },
        })),
      };
    },
  },
  created() {
    if (!this.shouldRender) {
      this.$emit('nothing-to-render');
    }
  },
};
</script>

<template>
  <gl-disclosure-dropdown-group v-if="shouldRender" v-bind="$attrs" :group="group" />
</template>
