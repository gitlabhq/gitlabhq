<script>
import {
  GlDropdownItem,
  GlDropdownSectionHeader,
  GlDropdownDivider,
  GlAvatar,
  GlLoadingIcon,
  GlSafeHtmlDirective as SafeHtml,
} from '@gitlab/ui';
import { mapState, mapGetters } from 'vuex';
import highlight from '~/lib/utils/highlight';
import { GROUPS_CATEGORY, PROJECTS_CATEGORY, LARGE_AVATAR_PX, SMALL_AVATAR_PX } from '../constants';

export default {
  name: 'HeaderSearchAutocompleteItems',
  components: {
    GlDropdownItem,
    GlDropdownSectionHeader,
    GlDropdownDivider,
    GlAvatar,
    GlLoadingIcon,
  },
  directives: {
    SafeHtml,
  },
  computed: {
    ...mapState(['search', 'loading']),
    ...mapGetters(['autocompleteGroupedSearchOptions']),
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
          v-for="(data, index) in option.data"
          :id="`autocomplete-${option.category}-${index}`"
          :key="index"
          tabindex="-1"
          :href="data.url"
        >
          <div class="gl-display-flex gl-align-items-center">
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
  </div>
</template>
