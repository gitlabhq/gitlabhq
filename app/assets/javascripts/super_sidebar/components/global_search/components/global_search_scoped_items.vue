<script>
import { GlIcon, GlDisclosureDropdownGroup } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapGetters } from 'vuex';
import { s__, sprintf } from '~/locale';
import { truncate } from '~/lib/utils/text_utility';
import { OVERLAY_SEARCH } from '../command_palette/constants';
import { SCOPE_TOKEN_MAX_LENGTH } from '../constants';
import SearchResultHoverLayover from './global_search_hover_overlay.vue';

export default {
  name: 'GlobalSearchScopedItems',
  components: {
    GlIcon,
    GlDisclosureDropdownGroup,
    SearchResultHoverLayover,
  },
  i18n: {
    OVERLAY_SEARCH,
  },
  computed: {
    ...mapState(['search']),
    ...mapGetters(['scopedSearchGroup']),
    group() {
      return {
        name: this.scopedSearchGroup.name,
        items: this.scopedSearchGroup.items.map((item) => ({
          ...item,
          extraAttrs: {
            class: 'show-hover-layover',
          },
        })),
      };
    },
  },
  methods: {
    titleLabel(item) {
      return sprintf(s__('GlobalSearch|in %{scope}'), {
        search: this.search,
        scope: item.scope || item.description,
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
    <ul class="gl-m-0 gl-p-0 gl-pb-2 gl-list-style-none" data-testid="scoped-items">
      <gl-disclosure-dropdown-group :group="group" bordered class="gl-mt-0!">
        <template #list-item="{ item }">
          <span class="gl-display-flex gl-align-items-center gl-justify-content-space-between">
            <span class="gl-display-flex gl-align-items-center">
              <gl-icon
                name="search-results"
                class="gl-flex-shrink-0 gl-mr-2 gl-pt-2 gl-mt-n2 gl-text-gray-500"
              />
              <span class="gl-flex-grow-1">
                {{ item.scope || item.description }}
              </span>
            </span>
            <search-result-hover-layover :text-message="$options.i18n.OVERLAY_SEARCH" />
          </span>
        </template>
      </gl-disclosure-dropdown-group>
    </ul>
  </div>
</template>
