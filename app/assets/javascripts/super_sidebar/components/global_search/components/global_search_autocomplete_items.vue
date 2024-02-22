<script>
import { GlAvatar, GlAlert, GlLoadingIcon, GlDisclosureDropdownGroup } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapGetters } from 'vuex';
import SafeHtml from '~/vue_shared/directives/safe_html';
import highlight from '~/lib/utils/highlight';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';
import {
  AUTOCOMPLETE_ERROR_MESSAGE,
  NO_SEARCH_RESULTS,
} from '~/vue_shared/global_search/constants';
import {
  OVERLAY_GOTO,
  OVERLAY_PROFILE,
  OVERLAY_PROJECT,
  OVERLAY_FILE,
  USERS_GROUP_TITLE,
  PROJECTS_GROUP_TITLE,
  ISSUE_GROUP_TITLE,
  PAGES_GROUP_TITLE,
} from '../command_palette/constants';
import SearchResultHoverLayover from './global_search_hover_overlay.vue';
import GlobalSearchNoResults from './global_search_no_results.vue';

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
    ISSUE_GROUP_TITLE,
    PAGES_GROUP_TITLE,
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
                class:
                  'show-hover-layover gl-display-flex gl-align-items-center gl-justify-content-space-between',
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
        case this.$options.i18n.ISSUE_GROUP_TITLE:
          text = this.$options.i18n.OVERLAY_GOTO;
          break;
        case this.$options.i18n.PAGES_GROUP_TITLE:
          text = this.$options.i18n.OVERLAY_FILE;
          break;
        default:
      }
      return text;
    },
  },
  AVATAR_SHAPE_OPTION_RECT,
};
</script>

<template>
  <div>
    <gl-alert
      v-if="autocompleteError"
      class="gl-text-body gl-mt-2"
      :dismissible="false"
      variant="danger"
    >
      {{ $options.i18n.AUTOCOMPLETE_ERROR_MESSAGE }}
    </gl-alert>

    <ul v-if="!loading && hasResults" class="gl-m-0 gl-p-0 gl-list-style-none">
      <gl-disclosure-dropdown-group
        v-for="(group, index) in groups"
        :key="group.name"
        :class="{ 'gl-mt-0!': index === 0 }"
        :group="group"
        bordered
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
            <span class="gl-display-flex gl-flex-direction-column gl-flex-grow-1 gl-min-w-0">
              <span
                v-safe-html="highlightedName(item.text)"
                class="gl-text-gray-900 gl-text-truncate"
                data-testid="autocomplete-item-name"
              ></span>
              <span
                v-if="item.value"
                v-safe-html="item.namespace"
                class="gl-font-sm gl-text-gray-500 gl-text-truncate"
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
