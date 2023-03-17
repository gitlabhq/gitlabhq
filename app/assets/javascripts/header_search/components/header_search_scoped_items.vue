<script>
import { GlDropdownItem, GlIcon, GlToken } from '@gitlab/ui';
import { mapState, mapGetters } from 'vuex';
import { s__, sprintf } from '~/locale';
import { truncate } from '~/lib/utils/text_utility';
import { SCOPED_SEARCH_ITEM_ARIA_LABEL } from '~/vue_shared/global_search/constants';
import { SCOPE_TOKEN_MAX_LENGTH } from '../constants';

export default {
  name: 'HeaderSearchScopedItems',
  i18n: {
    SCOPED_SEARCH_ITEM_ARIA_LABEL,
  },
  components: {
    GlDropdownItem,
    GlIcon,
    GlToken,
  },
  props: {
    currentFocusedOption: {
      type: Object,
      required: false,
      default: () => null,
    },
  },
  computed: {
    ...mapState(['search']),
    ...mapGetters(['scopedSearchOptions', 'autocompleteGroupedSearchOptions']),
  },
  methods: {
    isOptionFocused(option) {
      return this.currentFocusedOption?.html_id === option.html_id;
    },
    ariaLabel(option) {
      return sprintf(this.$options.i18n.SCOPED_SEARCH_ITEM_ARIA_LABEL, {
        search: this.search,
        description: option.description || option.icon,
        scope: option.scope || '',
      });
    },
    titleLabel(option) {
      return sprintf(s__('GlobalSearch|in %{scope}'), {
        search: this.search,
        scope: option.scope || option.description,
      });
    },
    getTruncatedScope(scope) {
      return truncate(scope, SCOPE_TOKEN_MAX_LENGTH);
    },
  },
};
</script>

<template>
  <div>
    <gl-dropdown-item
      v-for="option in scopedSearchOptions"
      :id="option.html_id"
      :ref="option.html_id"
      :key="option.html_id"
      class="gl-max-w-full"
      :class="{ 'gl-bg-gray-50': isOptionFocused(option) }"
      :aria-selected="isOptionFocused(option)"
      :aria-label="ariaLabel(option)"
      tabindex="-1"
      :href="option.url"
      :title="titleLabel(option)"
    >
      <span
        ref="token-text-content"
        class="gl-display-flex gl-justify-content-start search-text-content gl-line-height-24 gl-align-items-start gl-flex-direction-row gl-w-full"
      >
        <gl-icon name="search" class="gl-flex-shrink-0 gl-mr-2 gl-relative gl-pt-2" />
        <span class="gl-flex-grow-1 gl-relative">
          <gl-token
            class="in-dropdown-scope-help has-icon gl-flex-shrink-0 gl-relative gl-white-space-nowrap gl-float-right gl-mr-n3!"
            :view-only="true"
          >
            <gl-icon v-if="option.icon" :name="option.icon" class="gl-mr-2" />
            <span>{{ getTruncatedScope(titleLabel(option)) }}</span>
          </gl-token>
          {{ search }}
        </span>
      </span>
    </gl-dropdown-item>
  </div>
</template>
