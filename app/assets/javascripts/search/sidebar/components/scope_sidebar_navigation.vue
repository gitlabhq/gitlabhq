<script>
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapGetters } from 'vuex';
import { s__ } from '~/locale';
import NavItem from '~/super_sidebar/components/nav_item.vue';
import { NAV_LINK_DEFAULT_CLASSES, NAV_LINK_COUNT_DEFAULT_CLASSES } from '../constants';

export default {
  name: 'ScopeSidebarNavigation',
  i18n: {
    countOverLimitLabel: s__('GlobalSearch|Result count is over limit.'),
  },
  components: {
    NavItem,
  },
  computed: {
    ...mapGetters(['navigationItems']),
  },
  created() {
    this.fetchSidebarCount();
  },
  methods: {
    ...mapActions(['fetchSidebarCount']),
  },
  NAV_LINK_DEFAULT_CLASSES,
  NAV_LINK_COUNT_DEFAULT_CLASSES,
};
</script>

<template>
  <nav data-testid="search-filter" class="gl-relative gl-py-2">
    <ul class="gl-list-none gl-px-2">
      <nav-item v-for="item in navigationItems" :key="`menu-${item.title}`" :item="item" />
    </ul>
  </nav>
</template>
