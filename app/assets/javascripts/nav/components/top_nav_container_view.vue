<script>
import FrequentItemsApp from '~/frequent_items/components/app.vue';
import eventHub from '~/frequent_items/event_hub';
import VuexModuleProvider from '~/vue_shared/components/vuex_module_provider.vue';
import TopNavMenuSections from './top_nav_menu_sections.vue';

export default {
  components: {
    FrequentItemsApp,
    TopNavMenuSections,
    VuexModuleProvider,
  },
  inheritAttrs: false,
  props: {
    frequentItemsVuexModule: {
      type: String,
      required: true,
    },
    frequentItemsDropdownType: {
      type: String,
      required: true,
    },
    currentItem: {
      type: Object,
      required: true,
    },
    containerClass: {
      type: String,
      required: false,
      default: '',
    },
    linksPrimary: {
      type: Array,
      required: false,
      default: () => [],
    },
    linksSecondary: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    menuSections() {
      return [
        { id: 'primary', menuItems: this.linksPrimary },
        { id: 'secondary', menuItems: this.linksSecondary },
      ].filter((x) => x.menuItems?.length);
    },
    currentItemTimestamped() {
      return {
        ...this.currentItem,
        lastAccessedOn: Date.now(),
      };
    },
  },
  mounted() {
    // For historic reasons, the frequent-items-app component requires this too start up.
    this.$nextTick(() => {
      eventHub.$emit(`${this.frequentItemsDropdownType}-dropdownOpen`);
    });
  },
};
</script>

<template>
  <div class="top-nav-container-view gl-display-flex gl-flex-direction-column">
    <div
      class="frequent-items-dropdown-container gl-w-auto"
      :class="containerClass"
      data-testid="frequent-items-container"
    >
      <div class="frequent-items-dropdown-content gl-w-full! gl-pt-0!">
        <vuex-module-provider :vuex-module="frequentItemsVuexModule">
          <frequent-items-app :current-item="currentItemTimestamped" v-bind="$attrs" />
        </vuex-module-provider>
      </div>
    </div>
    <top-nav-menu-sections class="gl-mt-auto" :sections="menuSections" with-top-border />
  </div>
</template>
