<script>
import {
  GlDropdownItem,
  GlDropdownSectionHeader,
  GlDropdownDivider,
  GlAvatar,
  GlAlert,
  GlLoadingIcon,
  GlSafeHtmlDirective as SafeHtml,
} from '@gitlab/ui';
import { mapState, mapGetters } from 'vuex';
import { s__ } from '~/locale';
import highlight from '~/lib/utils/highlight';
import { GROUPS_CATEGORY, PROJECTS_CATEGORY, LARGE_AVATAR_PX, SMALL_AVATAR_PX } from '../constants';

export default {
  name: 'HeaderSearchAutocompleteItems',
  i18n: {
    autocompleteErrorMessage: s__(
      'GlobalSearch|There was an error fetching search autocomplete suggestions.',
    ),
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
    ...mapState(['search', 'loading', 'autocompleteError']),
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
  },
};
</script>

<template>
  <div>
    <template v-if="!loading">
      <div v-for="option in autocompleteGroupedSearchOptions" :key="option.category">
        <gl-dropdown-divider />
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
              :entity-id="data.id"
              :entity-name="data.label"
              :size="avatarSize(data)"
              shape="square"
            />
            <span v-safe-html="highlightedName(data.label)"></span>
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
      {{ $options.i18n.autocompleteErrorMessage }}
    </gl-alert>
  </div>
</template>
