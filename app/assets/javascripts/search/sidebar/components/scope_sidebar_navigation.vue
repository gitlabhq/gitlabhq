<script>
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapGetters } from 'vuex';
import { s__ } from '~/locale';
import NavItem from '~/super_sidebar/components/nav_item.vue';
import MenuSection from '~/super_sidebar/components/menu_section.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { NAV_LINK_DEFAULT_CLASSES, NAV_LINK_COUNT_DEFAULT_CLASSES } from '../constants';

export default {
  name: 'ScopeSidebarNavigation',
  i18n: {
    countOverLimitLabel: s__('GlobalSearch|Result count is over limit.'),
  },
  components: {
    NavItem,
    MenuSection,
  },
  mixins: [glFeatureFlagsMixin()],
  data() {
    return {
      showFlyoutMenus: false,
    };
  },
  computed: {
    ...mapGetters(['navigationItems', 'currentScope']),
  },
  created() {
    this.fetchSidebarCount();
  },
  methods: {
    ...mapActions(['fetchSidebarCount']),
    showWorkItems(subitems = []) {
      return this.glFeatures.workItemScopeFrontend && subitems.length > 0;
    },
  },
  NAV_LINK_DEFAULT_CLASSES,
  NAV_LINK_COUNT_DEFAULT_CLASSES,
};
</script>

<template>
  <nav data-testid="search-filter" class="gl-relative gl-py-2">
    <ul class="gl-list-none gl-px-2">
      <template v-for="item in navigationItems">
        <menu-section
          v-if="showWorkItems(item.items)"
          :key="item.id"
          :item="item"
          :separated="item.separated"
          :has-flyout="showFlyoutMenus"
          :expanded="true"
          tag="li"
        />
        <nav-item v-else :key="item.id" :item="item" />
      </template>
    </ul>
  </nav>
</template>
