<script>
import { GlAvatar, GlAlert, GlLoadingIcon, GlDisclosureDropdownGroup } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapGetters } from 'vuex';
import { s__ } from '~/locale';
import { InternalEvents } from '~/tracking';
import SafeHtml from '~/vue_shared/directives/safe_html';
import highlight from '~/lib/utils/highlight';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';
import {
  AUTOCOMPLETE_ERROR_MESSAGE,
  NO_SEARCH_RESULTS,
} from '~/vue_shared/global_search/constants';
import {
  EVENT_CLICK_PROJECT_RESULT_IN_COMMAND_PALETTE,
  EVENT_CLICK_GROUP_RESULT_IN_COMMAND_PALETTE,
  EVENT_CLICK_MERGE_REQUEST_RESULT_IN_COMMAND_PALETTE,
  EVENT_CLICK_ISSUE_RESULT_IN_COMMAND_PALETTE,
  EVENT_CLICK_RECENT_ISSUE_RESULT_IN_COMMAND_PALETTE,
  EVENT_CLICK_RECENT_EPIC_RESULT_IN_COMMAND_PALETTE,
  EVENT_CLICK_RECENT_MERGE_REQUEST_RESULT_IN_COMMAND_PALETTE,
  EVENT_CLICK_USER_RESULT_IN_COMMAND_PALETTE,
} from '~/super_sidebar/components/global_search/tracking_constants';
import {
  OVERLAY_GOTO,
  OVERLAY_PROFILE,
  OVERLAY_PROJECT,
  OVERLAY_FILE,
  USERS_GROUP_TITLE,
  PROJECTS_GROUP_TITLE,
  ISSUES_GROUP_TITLE,
  PAGES_GROUP_TITLE,
  GROUPS_GROUP_TITLE,
} from '../command_palette/constants';
import SearchResultHoverLayover from './global_search_hover_overlay.vue';
import GlobalSearchNoResults from './global_search_no_results.vue';

const trackingMixin = InternalEvents.mixin();

export default {
  name: 'GlobalSearchAutocompleteItems',
  i18n: {
    AUTOCOMPLETE_ERROR_MESSAGE,
    NO_SEARCH_RESULTS,
    OVERLAY_GOTO,
    OVERLAY_PROFILE,
    OVERLAY_PROJECT,
    OVERLAY_FILE,
    USERS_GROUP_TITLE,
    PROJECTS_GROUP_TITLE,
    ISSUES_GROUP_TITLE,
    PAGES_GROUP_TITLE,
    GROUPS_GROUP_TITLE,
    MERGE_REQUESTS_GROUP_TITLE: s__('GlobalSearch|Merge requests'),
    RECENT_ISSUES_GROUP_TITLE: s__('GlobalSearch|Recent issues'),
    RECENT_EPICS_GROUP_TITLE: s__('GlobalSearch|Recent epics'),
    RECENT_MERGE_REQUESTS_GROUP_TITLE: s__('GlobalSearch|Recent merge requests'),
  },
  components: {
    GlAvatar,
    GlAlert,
    GlLoadingIcon,
    GlDisclosureDropdownGroup,
    SearchResultHoverLayover,
    GlobalSearchNoResults,
  },
  directives: {
    SafeHtml,
  },
  mixins: [trackingMixin],
  computed: {
    ...mapState(['search', 'loading', 'autocompleteError']),
    ...mapGetters(['autocompleteGroupedSearchOptions', 'scopedSearchOptions']),
    groups() {
      return this.autocompleteGroupedSearchOptions.map((group) => {
        return {
          name: group?.name,
          items: group?.items?.map((item) => {
            return {
              ...item,
              extraAttrs: {
                class: 'show-hover-layover gl-flex gl-items-center gl-justify-between',
              },
            };
          }),
        };
      });
    },
    hasResults() {
      return this.autocompleteGroupedSearchOptions?.length > 0;
    },
    hasNoResults() {
      return !this.hasResults && !this.autocompleteError;
    },
  },
  methods: {
    highlightedName(val) {
      return highlight(val, this.search);
    },
    overlayText(group) {
      let text = OVERLAY_GOTO;

      switch (group) {
        case this.$options.i18n.USERS_GROUP_TITLE:
          text = this.$options.i18n.OVERLAY_PROFILE;
          break;
        case this.$options.i18n.PROJECTS_GROUP_TITLE:
          text = this.$options.i18n.OVERLAY_PROJECT;
          break;
        case this.$options.i18n.ISSUES_GROUP_TITLE:
          text = this.$options.i18n.OVERLAY_GOTO;
          break;
        case this.$options.i18n.PAGES_GROUP_TITLE:
          text = this.$options.i18n.OVERLAY_FILE;
          break;
        default:
      }
      return text;
    },
    trackingTypes({ name }) {
      switch (name) {
        case this.$options.i18n.PROJECTS_GROUP_TITLE: {
          this.trackEvent(EVENT_CLICK_PROJECT_RESULT_IN_COMMAND_PALETTE);
          break;
        }
        case this.$options.i18n.GROUPS_GROUP_TITLE: {
          this.trackEvent(EVENT_CLICK_GROUP_RESULT_IN_COMMAND_PALETTE);
          break;
        }
        case this.$options.i18n.MERGE_REQUESTS_GROUP_TITLE: {
          this.trackEvent(EVENT_CLICK_MERGE_REQUEST_RESULT_IN_COMMAND_PALETTE);
          break;
        }
        case this.$options.i18n.ISSUES_GROUP_TITLE: {
          this.trackEvent(EVENT_CLICK_ISSUE_RESULT_IN_COMMAND_PALETTE);
          break;
        }
        case this.$options.i18n.RECENT_ISSUES_GROUP_TITLE: {
          this.trackEvent(EVENT_CLICK_RECENT_ISSUE_RESULT_IN_COMMAND_PALETTE);
          break;
        }
        case this.$options.i18n.RECENT_EPICS_GROUP_TITLE: {
          this.trackEvent(EVENT_CLICK_RECENT_EPIC_RESULT_IN_COMMAND_PALETTE);
          break;
        }
        case this.$options.i18n.RECENT_MERGE_REQUESTS_GROUP_TITLE: {
          this.trackEvent(EVENT_CLICK_RECENT_MERGE_REQUEST_RESULT_IN_COMMAND_PALETTE);
          break;
        }

        default: {
          this.trackEvent(EVENT_CLICK_USER_RESULT_IN_COMMAND_PALETTE);
        }
      }
    },
  },
  AVATAR_SHAPE_OPTION_RECT,
};
</script>

<template>
  <div>
    <gl-alert
      v-if="autocompleteError"
      class="gl-mt-2 gl-text-default"
      :dismissible="false"
      variant="danger"
    >
      {{ $options.i18n.AUTOCOMPLETE_ERROR_MESSAGE }}
    </gl-alert>

    <ul v-if="!loading && hasResults" class="gl-m-0 gl-list-none gl-p-0">
      <gl-disclosure-dropdown-group
        v-for="(group, index) in groups"
        :key="group.name"
        :class="{ '!gl-mt-0': index === 0 }"
        :group="group"
        bordered
        @action="trackingTypes"
      >
        <template #list-item="{ item }">
          <search-result-hover-layover :text-message="overlayText(group.name)">
            <gl-avatar
              v-if="item.avatar_url !== undefined"
              :src="item.avatar_url"
              :entity-id="item.entity_id"
              :entity-name="item.entity_name"
              :size="item.avatar_size"
              :shape="$options.AVATAR_SHAPE_OPTION_RECT"
              aria-hidden="true"
            />
            <span class="gl-flex gl-min-w-0 gl-grow gl-flex-col">
              <span
                v-safe-html="highlightedName(item.text)"
                class="gl-truncate gl-text-strong"
                data-testid="autocomplete-item-name"
              ></span>
              <span
                v-if="item.value"
                v-safe-html="item.namespace"
                class="gl-truncate gl-text-sm gl-text-subtle"
                data-testid="autocomplete-item-namespace"
              ></span>
            </span>
          </search-result-hover-layover>
        </template>
      </gl-disclosure-dropdown-group>
    </ul>

    <gl-loading-icon v-if="loading" size="lg" class="gl-my-6" />

    <global-search-no-results v-if="hasNoResults" />
  </div>
</template>
