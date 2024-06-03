<script>
import { GlDisclosureDropdownGroup } from '@gitlab/ui';
import { kebabCase } from 'lodash';
import { s__ } from '~/locale';
import { InternalEvents } from '~/tracking';
import { PLACES } from '~/vue_shared/global_search/constants';
import { TRACKING_UNKNOWN_ID, TRACKING_UNKNOWN_PANEL } from '~/super_sidebar/constants';
import {
  EVENT_CLICK_YOUR_WORK_IN_COMMAND_PALETTE,
  EVENT_CLICK_EXPLORE_IN_COMMAND_PALETTE,
  EVENT_CLICK_PROFILE_IN_COMMAND_PALETTE,
  EVENT_CLICK_PREFERENCES_IN_COMMAND_PALETTE,
} from '~/super_sidebar/components/global_search/tracking_constants';
import {
  TRACKING_CLICK_COMMAND_PALETTE_ITEM,
  OVERLAY_CHANGE_CONTEXT,
} from '../command_palette/constants';
import SearchResultHoverLayover from './global_search_hover_overlay.vue';

const trackingMixin = InternalEvents.mixin();

export default {
  name: 'DefaultPlaces',
  i18n: {
    PLACES,
    OVERLAY_CHANGE_CONTEXT,
    YOUR_WORK_TITLE: s__('GlobalSearch|Your work'),
    EXPLORE_TITLE: s__('GlobalSearch|Explore'),
    PROFILE_TITLE: s__('GlobalSearch|Profile'),
    PREFERENCES_TITLE: s__('GlobalSearch|Preferences'),
  },
  components: {
    GlDisclosureDropdownGroup,
    SearchResultHoverLayover,
  },
  mixins: [trackingMixin],
  inject: ['contextSwitcherLinks'],
  computed: {
    shouldRender() {
      return this.contextSwitcherLinks.length > 0;
    },
    group() {
      return {
        name: this.$options.i18n.PLACES,
        items: this.contextSwitcherLinks.map(({ title, link, ...rest }) => ({
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

            // QA attributes
            'data-testid': 'places-item-link',
            'data-qa-places-item': title,

            // this is helper class for popover-hint
            class: 'show-hover-layover',

            // Any other data- attributes (e.g., for @rails/ujs)
            ...Object.entries(rest).reduce((acc, [name, value]) => {
              if (name.startsWith('data')) acc[kebabCase(name)] = value;
              return acc;
            }, {}),
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
  methods: {
    trackingTypes({ text }) {
      switch (text) {
        case this.$options.i18n.YOUR_WORK_TITLE: {
          this.trackEvent(EVENT_CLICK_YOUR_WORK_IN_COMMAND_PALETTE);
          break;
        }
        case this.$options.i18n.EXPLORE_TITLE: {
          this.trackEvent(EVENT_CLICK_EXPLORE_IN_COMMAND_PALETTE);
          break;
        }
        case this.$options.i18n.PROFILE_TITLE: {
          this.trackEvent(EVENT_CLICK_PROFILE_IN_COMMAND_PALETTE);
          break;
        }
        case this.$options.i18n.PREFERENCES_TITLE: {
          this.trackEvent(EVENT_CLICK_PREFERENCES_IN_COMMAND_PALETTE);
          break;
        }

        default: {
          /* empty */
        }
      }
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown-group
    v-if="shouldRender"
    v-bind="$attrs"
    :group="group"
    @action="trackingTypes"
  >
    <template #list-item="{ item }">
      <search-result-hover-layover :text-message="$options.i18n.OVERLAY_CHANGE_CONTEXT">
        <span>{{ item.text }}</span>
      </search-result-hover-layover>
    </template>
  </gl-disclosure-dropdown-group>
</template>
