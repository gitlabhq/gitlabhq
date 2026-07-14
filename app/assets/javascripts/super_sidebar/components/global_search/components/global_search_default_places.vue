<script>
import { GlDisclosureDropdownGroup, GlDisclosureDropdownItem } from '@gitlab/ui';
import { s__ } from '~/locale';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { InternalEvents } from '~/tracking';
import { PLACES } from '~/vue_shared/global_search/constants';
import { TRACKING_UNKNOWN_ID, TRACKING_UNKNOWN_PANEL } from '~/super_sidebar/constants';
import { adminRootPath } from '~/lib/utils/path_helpers/admin';
import { exploreRootPath } from '~/lib/utils/path_helpers/explore';
import { profilePreferencesPath } from '~/lib/utils/path_helpers/profile';
import { rootPath } from '~/lib/utils/path_helpers/routes';
import { userSettingsProfilePath } from '~/lib/utils/path_helpers/user_settings';
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
import SearchResultFocusLayover from './global_search_focus_overlay.vue';

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
    ADMIN_AREA_TITLE: s__('GlobalSearch|Admin area'),
  },
  components: {
    GlDisclosureDropdownGroup,
    GlDisclosureDropdownItem,
    SearchResultFocusLayover,
  },
  mixins: [trackingMixin],
  inject: {
    showAdminAreaLink: { default: false },
  },
  computed: {
    contextSwitcherLinks() {
      return [
        ...(isLoggedIn() ? [{ title: this.$options.i18n.YOUR_WORK_TITLE, link: rootPath() }] : []),
        { title: this.$options.i18n.EXPLORE_TITLE, link: exploreRootPath() },
        ...(isLoggedIn()
          ? [
              { title: this.$options.i18n.PROFILE_TITLE, link: userSettingsProfilePath() },
              { title: this.$options.i18n.PREFERENCES_TITLE, link: profilePreferencesPath() },
            ]
          : []),
        ...(this.showAdminAreaLink
          ? [{ title: this.$options.i18n.ADMIN_AREA_TITLE, link: adminRootPath() }]
          : []),
      ];
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

            // QA attributes
            'data-testid': 'places-item-link',
            'data-qa-places-item': title,

            // this is helper class for popover-hint
            class: 'show-focus-layover',
          },
        })),
      };
    },
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
  <gl-disclosure-dropdown-group v-bind="$attrs" :group="group" @action="trackingTypes">
    <gl-disclosure-dropdown-item
      v-for="item in group.items"
      :key="item.text"
      :item="item"
      class="show-on-focus-or-hover--context show-focus-layover"
    >
      <template #list-item>
        <search-result-focus-layover :text-message="$options.i18n.OVERLAY_CHANGE_CONTEXT">
          <span>{{ item.text }}</span>
        </search-result-focus-layover>
      </template>
    </gl-disclosure-dropdown-item>
  </gl-disclosure-dropdown-group>
</template>
