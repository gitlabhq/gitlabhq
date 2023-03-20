<script>
import {
  GlDropdownItem,
  GlDropdownSectionHeader,
  GlDropdownDivider,
  GlAvatar,
  GlAlert,
  GlLoadingIcon,
} from '@gitlab/ui';
import { mapState, mapGetters } from 'vuex';
import SafeHtml from '~/vue_shared/directives/safe_html';
import highlight from '~/lib/utils/highlight';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';
import { truncateNamespace } from '~/lib/utils/text_utility';
import {
  GROUPS_CATEGORY,
  PROJECTS_CATEGORY,
  MERGE_REQUEST_CATEGORY,
  ISSUES_CATEGORY,
  RECENT_EPICS_CATEGORY,
  AUTOCOMPLETE_ERROR_MESSAGE,
} from '~/vue_shared/global_search/constants';
import { LARGE_AVATAR_PX, SMALL_AVATAR_PX } from '../constants';

export default {
  name: 'HeaderSearchAutocompleteItems',
  i18n: {
    AUTOCOMPLETE_ERROR_MESSAGE,
  },
  components: {
    GlDropdownItem,
    GlDropdownSectionHeader,
    GlDropdownDivider,
    GlAvatar,
    GlAlert,
    GlLoadingIcon,
  },
  directives: {
    SafeHtml,
  },
  props: {
    currentFocusedOption: {
      type: Object,
      required: false,
      default: () => null,
    },
  },
  computed: {
    ...mapState(['search', 'loading', 'autocompleteError', 'searchContext']),
    ...mapGetters(['autocompleteGroupedSearchOptions']),
  },
  watch: {
    currentFocusedOption() {
      const focusedElement = this.$refs[this.currentFocusedOption?.html_id]?.[0]?.$el;

      if (focusedElement) {
        focusedElement.scrollIntoView(false);
      }
    },
  },
  methods: {
    truncateNamespace(string) {
      if (string.split(' / ').length > 2) {
        return truncateNamespace(string);
      }

      return string;
    },
    highlightedName(val) {
      return highlight(val, this.search);
    },
    avatarSize(data) {
      if (data.category === GROUPS_CATEGORY || data.category === PROJECTS_CATEGORY) {
        return LARGE_AVATAR_PX;
      }

      return SMALL_AVATAR_PX;
    },
    isOptionFocused(data) {
      return this.currentFocusedOption?.html_id === data.html_id;
    },
    isProjectsCategory(data) {
      return data.category === PROJECTS_CATEGORY;
    },
    getEntityId(data) {
      switch (data.category) {
        case GROUPS_CATEGORY:
        case RECENT_EPICS_CATEGORY:
          return data.group_id || data.id || this.searchContext?.group?.id;
        case PROJECTS_CATEGORY:
        case ISSUES_CATEGORY:
        case MERGE_REQUEST_CATEGORY:
          return data.project_id || data.id || this.searchContext?.project?.id;
        default:
          return data.id;
      }
    },
    getEntitytName(data) {
      switch (data.category) {
        case GROUPS_CATEGORY:
        case RECENT_EPICS_CATEGORY:
          return data.group_name || data.value || data.label || this.searchContext?.group?.name;
        case PROJECTS_CATEGORY:
        case ISSUES_CATEGORY:
        case MERGE_REQUEST_CATEGORY:
          return data.project_name || data.value || data.label || this.searchContext?.project?.name;
        default:
          return data.label;
      }
    },
  },
  AVATAR_SHAPE_OPTION_RECT,
};
</script>

<template>
  <div>
    <template v-if="!loading">
      <div v-for="(option, index) in autocompleteGroupedSearchOptions" :key="option.category">
        <gl-dropdown-divider v-if="index > 0" />
        <gl-dropdown-section-header>{{ option.category }}</gl-dropdown-section-header>
        <gl-dropdown-item
          v-for="data in option.data"
          :id="data.html_id"
          :ref="data.html_id"
          :key="data.html_id"
          :class="{ 'gl-bg-gray-50': isOptionFocused(data) }"
          :aria-selected="isOptionFocused(data)"
          :aria-label="data.label"
          tabindex="-1"
          :href="data.url"
        >
          <div class="gl-display-flex gl-align-items-center" aria-hidden="true">
            <gl-avatar
              v-if="data.avatar_url !== undefined"
              :src="data.avatar_url"
              :entity-id="getEntityId(data)"
              :entity-name="getEntitytName(data)"
              :size="avatarSize(data)"
              :shape="$options.AVATAR_SHAPE_OPTION_RECT"
            />
            <span class="gl-display-flex gl-flex-direction-column">
              <span
                v-safe-html="highlightedName(data.value || data.label)"
                class="gl-text-gray-900"
              ></span>
              <span
                v-if="data.value"
                v-safe-html="truncateNamespace(data.label)"
                class="gl-font-sm gl-text-gray-500"
              ></span>
            </span>
          </div>
        </gl-dropdown-item>
      </div>
    </template>
    <gl-loading-icon v-else size="lg" class="my-4" />
    <gl-alert
      v-if="autocompleteError"
      class="gl-text-body gl-mt-2"
      :dismissible="false"
      variant="danger"
    >
      {{ $options.i18n.AUTOCOMPLETE_ERROR_MESSAGE }}
    </gl-alert>
  </div>
</template>
