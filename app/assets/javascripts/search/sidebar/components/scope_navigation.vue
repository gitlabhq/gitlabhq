<script>
import { GlNav, GlNavItem, GlIcon } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import { NAV_LINK_DEFAULT_CLASSES, NAV_LINK_COUNT_DEFAULT_CLASSES } from '../constants';
import { formatSearchResultCount } from '../../store/utils';

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
    this.fetchSidebarCount();
  },
  methods: {
    ...mapActions(['fetchSidebarCount']),
    showFormatedCount(count) {
      return formatSearchResultCount(count);
    },
    isCountOverLimit(count) {
      return count.includes('+');
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
    isActive(scope, index) {
      return this.urlQuery.scope ? this.urlQuery.scope === scope : index === 0;
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
        v-for="(item, scope, index) in navigation"
        :key="scope"
        :link-classes="linkClasses(isActive(scope, index))"
        class="gl-mb-1"
        :href="item.link"
        :active="isActive(scope, index)"
        @click="handleClick(scope)"
        ><span>{{ item.label }}</span
        ><span v-if="item.count" :class="countClasses(isActive(scope, index))">
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
