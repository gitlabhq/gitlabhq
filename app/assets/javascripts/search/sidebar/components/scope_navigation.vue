<script>
import { GlNav, GlNavItem } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import { formatNumber } from '~/locale';
import Tracking from '~/tracking';
import { NAV_LINK_DEFAULT_CLASSES, NUMBER_FORMATING_OPTIONS } from '../constants';

export default {
  name: 'ScopeNavigation',
  components: {
    GlNav,
    GlNavItem,
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
    activeClasses(currentScope) {
      return currentScope === this.urlQuery.scope ? 'gl-font-weight-bold' : '';
    },
    showFormatedCount(count) {
      if (!count) {
        return '0';
      }
      const countNumber = parseInt(count.replace(/,/g, ''), 10);
      return formatNumber(countNumber, NUMBER_FORMATING_OPTIONS);
    },
    handleClick(scope) {
      this.track('click_menu_item', { label: `vertical_navigation_${scope}` });
    },
    linkClasses(scope) {
      return [
        { 'gl-font-weight-bold': scope === this.urlQuery.scope },
        ...this.$options.NAV_LINK_DEFAULT_CLASSES,
      ];
    },
  },
  NAV_LINK_DEFAULT_CLASSES,
};
</script>

<template>
  <nav>
    <gl-nav vertical pills>
      <gl-nav-item
        v-for="(item, scope, index) in navigation"
        :key="scope"
        :link-classes="linkClasses(scope)"
        class="gl-mb-1"
        :href="item.link"
        :active="urlQuery.scope ? urlQuery.scope === scope : index === 0"
        @click="handleClick(scope)"
        ><span>{{ item.label }}</span
        ><span v-if="item.count" class="gl-font-sm gl-font-weight-normal">
          {{ showFormatedCount(item.count) }}
        </span>
      </gl-nav-item>
    </gl-nav>
    <hr class="gl-mt-5 gl-mb-0 gl-border-gray-100 gl-md-display-none" />
  </nav>
</template>
