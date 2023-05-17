<script>
import { mapActions, mapState, mapGetters } from 'vuex';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import NavItem from '~/super_sidebar/components/nav_item.vue';
import { NAV_LINK_DEFAULT_CLASSES, NAV_LINK_COUNT_DEFAULT_CLASSES } from '../constants';

export default {
  name: 'ScopeNewNavigation',
  i18n: {
    countOverLimitLabel: s__('GlobalSearch|Result count is over limit.'),
  },
  components: {
    NavItem,
  },
  mixins: [Tracking.mixin()],
  computed: {
    ...mapState(['navigation', 'urlQuery']),
    ...mapGetters(['navigationItems']),
  },
  created() {
    if (this.urlQuery?.search) {
      this.fetchSidebarCount();
    }
  },
  methods: {
    ...mapActions(['fetchSidebarCount']),
  },
  NAV_LINK_DEFAULT_CLASSES,
  NAV_LINK_COUNT_DEFAULT_CLASSES,
};
</script>

<template>
  <nav data-testid="search-filter" class="gl-py-2 gl-relative">
    <ul class="gl-px-2 gl-list-style-none">
      <nav-item v-for="item in navigationItems" :key="`menu-${item.title}`" :item="item" />
    </ul>
  </nav>
</template>
