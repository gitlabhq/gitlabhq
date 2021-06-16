<script>
import { FREQUENT_ITEMS_PROJECTS, FREQUENT_ITEMS_GROUPS } from '~/frequent_items/constants';
import { BV_DROPDOWN_SHOW, BV_DROPDOWN_HIDE } from '~/lib/utils/constants';
import KeepAliveSlots from '~/vue_shared/components/keep_alive_slots.vue';
import eventHub, { EVENT_RESPONSIVE_TOGGLE } from '../event_hub';
import { resetMenuItemsActive, hasMenuExpanded } from '../utils';
import ResponsiveHeader from './responsive_header.vue';
import ResponsiveHome from './responsive_home.vue';
import TopNavContainerView from './top_nav_container_view.vue';

export default {
  components: {
    KeepAliveSlots,
    ResponsiveHeader,
    ResponsiveHome,
    TopNavContainerView,
  },
  props: {
    navData: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      activeView: 'home',
      hasMobileOverlay: false,
    };
  },
  computed: {
    nav() {
      return resetMenuItemsActive(this.navData);
    },
  },
  created() {
    eventHub.$on(EVENT_RESPONSIVE_TOGGLE, this.updateResponsiveOpen);
    this.$root.$on(BV_DROPDOWN_SHOW, this.showMobileOverlay);
    this.$root.$on(BV_DROPDOWN_HIDE, this.hideMobileOverlay);

    this.updateResponsiveOpen();
  },
  beforeDestroy() {
    eventHub.$off(EVENT_RESPONSIVE_TOGGLE, this.onToggle);
    this.$root.$off(BV_DROPDOWN_SHOW, this.showMobileOverlay);
    this.$root.$off(BV_DROPDOWN_HIDE, this.hideMobileOverlay);
  },
  methods: {
    updateResponsiveOpen() {
      if (hasMenuExpanded()) {
        document.body.classList.add('top-nav-responsive-open');
      } else {
        document.body.classList.remove('top-nav-responsive-open');
      }
    },
    onMenuItemClick({ view }) {
      if (view) {
        this.activeView = view;
      }
    },
    showMobileOverlay() {
      this.hasMobileOverlay = true;
    },
    hideMobileOverlay() {
      this.hasMobileOverlay = false;
    },
  },
  FREQUENT_ITEMS_PROJECTS,
  FREQUENT_ITEMS_GROUPS,
};
</script>

<template>
  <div>
    <div
      class="mobile-overlay"
      :class="{ 'mobile-nav-open': hasMobileOverlay }"
      data-testid="mobile-overlay"
    ></div>
    <keep-alive-slots :slot-key="activeView">
      <template #home>
        <responsive-home :nav-data="nav" @menu-item-click="onMenuItemClick" />
      </template>
      <template #projects>
        <responsive-header @menu-item-click="onMenuItemClick">
          {{ __('Projects') }}
        </responsive-header>
        <top-nav-container-view
          :frequent-items-dropdown-type="$options.FREQUENT_ITEMS_PROJECTS.namespace"
          :frequent-items-vuex-module="$options.FREQUENT_ITEMS_PROJECTS.vuexModule"
          container-class="gl-px-3"
          v-bind="nav.views.projects"
        />
      </template>
      <template #groups>
        <responsive-header @menu-item-click="onMenuItemClick">
          {{ __('Groups') }}
        </responsive-header>
        <top-nav-container-view
          :frequent-items-dropdown-type="$options.FREQUENT_ITEMS_GROUPS.namespace"
          :frequent-items-vuex-module="$options.FREQUENT_ITEMS_GROUPS.vuexModule"
          container-class="gl-px-3"
          v-bind="nav.views.groups"
        />
      </template>
    </keep-alive-slots>
  </div>
</template>
