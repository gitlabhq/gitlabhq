<script>
import { GlNav, GlNavItem, GlIcon } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import { formatSearchResultCount, addCountOverLimit } from '~/search/store/utils';
import { NAV_LINK_DEFAULT_CLASSES, NAV_LINK_COUNT_DEFAULT_CLASSES } from '../constants';
import { slugifyWithUnderscore } from '../../../lib/utils/text_utility';

export default {
  name: 'ScopeNavigation',
  i18n: {
    countOverLimitLabel: s__('GlobalSearch|Result count is over limit.'),
  },
  components: {
    GlNav,
    GlNavItem,
    GlIcon,
  },
  mixins: [Tracking.mixin()],
  computed: {
    ...mapState(['navigation', 'urlQuery']),
  },
  created() {
    if (this.urlQuery?.search) {
      this.fetchSidebarCount();
    }
  },
  methods: {
    ...mapActions(['fetchSidebarCount']),
    showFormatedCount(countString) {
      return formatSearchResultCount(countString);
    },
    isCountOverLimit(countString) {
      return Boolean(addCountOverLimit(countString));
    },
    handleClick(scope) {
      this.track('click_menu_item', { label: `vertical_navigation_${scope}` });
    },
    linkClasses(isHighlighted) {
      return [...this.$options.NAV_LINK_DEFAULT_CLASSES, { 'gl-font-weight-bold': isHighlighted }];
    },
    countClasses(isHighlighted) {
      return [
        ...this.$options.NAV_LINK_COUNT_DEFAULT_CLASSES,
        isHighlighted ? 'gl-text-gray-900' : 'gl-text-gray-500',
      ];
    },
    qaSelectorValue(item) {
      return `${slugifyWithUnderscore(item.label)}_tab`;
    },
  },
  NAV_LINK_DEFAULT_CLASSES,
  NAV_LINK_COUNT_DEFAULT_CLASSES,
};
</script>

<template>
  <nav data-testid="search-filter">
    <gl-nav vertical pills>
      <gl-nav-item
        v-for="(item, scope) in navigation"
        :key="scope"
        :link-classes="linkClasses(item.active)"
        class="gl-mb-1"
        :href="item.link"
        :active="item.active"
        :data-qa-selector="qaSelectorValue(item)"
        :data-testid="qaSelectorValue(item)"
        @click="handleClick(scope)"
        ><span data-testid="label">{{ item.label }}</span
        ><span v-if="item.count" data-testid="count" :class="countClasses(item.active)">
          {{ showFormatedCount(item.count)
          }}<gl-icon
            v-if="isCountOverLimit(item.count)"
            name="plus"
            :aria-label="$options.i18n.countOverLimitLabel"
            :size="8"
          />
        </span>
      </gl-nav-item>
    </gl-nav>
    <hr class="gl-mt-5 gl-mx-5 gl-mb-0 gl-border-gray-100 gl-md-display-none" />
  </nav>
</template>
