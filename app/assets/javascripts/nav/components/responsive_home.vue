<script>
import { GlTooltipDirective } from '@gitlab/ui';
import TopNavMenuItem from './top_nav_menu_item.vue';
import TopNavMenuSections from './top_nav_menu_sections.vue';
import TopNavNewDropdown from './top_nav_new_dropdown.vue';

const NEW_VIEW = 'new';
const SEARCH_VIEW = 'search';

export default {
  components: {
    TopNavMenuItem,
    TopNavMenuSections,
    TopNavNewDropdown,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    navData: {
      type: Object,
      required: true,
    },
  },
  computed: {
    menuSections() {
      return [
        { id: 'primary', menuItems: this.navData.primary },
        { id: 'secondary', menuItems: this.navData.secondary },
      ].filter((x) => x.menuItems?.length);
    },
    newDropdownViewModel() {
      return this.navData.views[NEW_VIEW];
    },
    searchMenuItem() {
      return this.navData.views[SEARCH_VIEW];
    },
  },
};
</script>

<template>
  <div>
    <header class="gl-display-flex gl-align-items-center gl-py-4 gl-pl-4">
      <h1 class="gl-m-0 gl-font-size-h2 gl-reset-color gl-mr-auto">{{ __('Menu') }}</h1>
      <top-nav-menu-item
        v-if="searchMenuItem"
        v-gl-tooltip="{ title: searchMenuItem.title }"
        class="gl-ml-3"
        :menu-item="searchMenuItem"
        icon-only
      />
      <top-nav-new-dropdown
        v-if="newDropdownViewModel"
        v-gl-tooltip="{ title: newDropdownViewModel.title }"
        :view-model="newDropdownViewModel"
        class="gl-ml-3"
        data-qa-selector="mobile_new_dropdown"
      />
    </header>
    <top-nav-menu-sections class="gl-h-full" :sections="menuSections" v-on="$listeners" />
  </div>
</template>
