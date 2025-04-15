<script>
import { GlIcon, GlDisclosureDropdownGroup, GlDisclosureDropdownItem } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapGetters, mapState } from 'vuex';
import { InternalEvents } from '~/tracking';
import {
  EVENT_CLICK_ALL_GITLAB_SCOPED_SEARCH_TO_ADVANCED_SEARCH,
  EVENT_CLICK_GROUP_SCOPED_SEARCH_TO_ADVANCED_SEARCH,
  EVENT_CLICK_PROJECT_SCOPED_SEARCH_TO_ADVANCED_SEARCH,
} from '~/super_sidebar/components/global_search/tracking_constants';
import { injectRegexSearch, injectUsersScope } from '~/search/store/utils';
import {
  OVERLAY_SEARCH,
  SCOPE_SEARCH_ALL,
  SCOPE_SEARCH_GROUP,
  SCOPE_SEARCH_PROJECT,
  USER_HANDLE,
} from '../command_palette/constants';
import SearchResultFocusLayover from './global_search_focus_overlay.vue';

const trackingMixin = InternalEvents.mixin();

export default {
  name: 'GlobalSearchScopedItems',
  components: {
    GlIcon,
    GlDisclosureDropdownGroup,
    GlDisclosureDropdownItem,
    SearchResultFocusLayover,
  },
  mixins: [trackingMixin],
  i18n: {
    OVERLAY_SEARCH,
  },
  computed: {
    ...mapState(['commandChar']),
    ...mapGetters(['scopedSearchGroup']),
    group() {
      return {
        name: this.scopedSearchGroup.name,
        items: this.scopedSearchGroup.items.map((item) => ({
          ...item,
          href: this.injectSearchPropsToHref(item),
          scopeName: item.scope || item.description,
          extraAttrs: {
            class: 'show-focus-layover',
          },
        })),
      };
    },
  },
  methods: {
    injectSearchPropsToHref(item) {
      if (item.text === SCOPE_SEARCH_PROJECT) {
        return injectRegexSearch(item.href);
      }
      if (this.commandChar === this.$options.USER_HANDLE) {
        return injectUsersScope(item.href);
      }

      return item.href;
    },
    trackingTypes({ text }) {
      switch (text) {
        case this.$options.SCOPE_SEARCH_ALL: {
          this.trackEvent(EVENT_CLICK_ALL_GITLAB_SCOPED_SEARCH_TO_ADVANCED_SEARCH);
          break;
        }
        case this.$options.SCOPE_SEARCH_GROUP: {
          this.trackEvent(EVENT_CLICK_GROUP_SCOPED_SEARCH_TO_ADVANCED_SEARCH);
          break;
        }
        case this.$options.SCOPE_SEARCH_PROJECT: {
          this.trackEvent(EVENT_CLICK_PROJECT_SCOPED_SEARCH_TO_ADVANCED_SEARCH);
          break;
        }
        default: {
          /* empty */
        }
      }
    },
  },
  SCOPE_SEARCH_ALL,
  SCOPE_SEARCH_GROUP,
  SCOPE_SEARCH_PROJECT,
  USER_HANDLE,
};
</script>

<template>
  <div>
    <ul class="gl-m-0 gl-list-none gl-p-0 gl-pb-2" data-testid="scoped-items">
      <gl-disclosure-dropdown-group :group="group" @action="trackingTypes">
        <gl-disclosure-dropdown-item
          v-for="item in group.items"
          :key="item.text"
          :item="item"
          class="show-on-focus-or-hover--context show-focus-layover"
        >
          <template #list-item>
            <search-result-focus-layover :text-message="$options.i18n.OVERLAY_SEARCH">
              <gl-icon
                name="search-results"
                class="-gl-mt-2 gl-mr-2 gl-shrink-0 gl-pt-2 gl-text-subtle"
              />
              <span class="gl-grow">
                {{ item.scopeName }}
              </span>
            </search-result-focus-layover>
          </template>
        </gl-disclosure-dropdown-item>
      </gl-disclosure-dropdown-group>
    </ul>
  </div>
</template>
