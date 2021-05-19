<script>
import FrequentItemsApp from '~/frequent_items/components/app.vue';
import eventHub from '~/frequent_items/event_hub';
import VuexModuleProvider from '~/vue_shared/components/vuex_module_provider.vue';
import TopNavMenuItem from './top_nav_menu_item.vue';

export default {
  components: {
    FrequentItemsApp,
    TopNavMenuItem,
    VuexModuleProvider,
  },
  props: {
    frequentItemsVuexModule: {
      type: String,
      required: true,
    },
    frequentItemsDropdownType: {
      type: String,
      required: true,
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
    linkGroups() {
      return [
        { key: 'primary', links: this.linksPrimary },
        { key: 'secondary', links: this.linksSecondary },
      ].filter((x) => x.links?.length);
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
    <div class="frequent-items-dropdown-container gl-w-auto">
      <div class="frequent-items-dropdown-content gl-w-full! gl-pt-0!">
        <vuex-module-provider :vuex-module="frequentItemsVuexModule">
          <frequent-items-app v-bind="$attrs" />
        </vuex-module-provider>
      </div>
    </div>
    <div
      v-for="({ key, links }, groupIndex) in linkGroups"
      :key="key"
      :class="{ 'gl-mt-3': groupIndex !== 0 }"
      class="gl-mt-auto gl-pt-3 gl-border-1 gl-border-t-solid gl-border-gray-100"
      data-testid="menu-item-group"
    >
      <top-nav-menu-item
        v-for="(link, linkIndex) in links"
        :key="link.title"
        :menu-item="link"
        :class="{ 'gl-mt-1': linkIndex !== 0 }"
      />
    </div>
  </div>
</template>
