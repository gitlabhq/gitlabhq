<script>
import { GlBadge, GlTabs, GlTab } from '@gitlab/ui';
import { initScrollingTabs } from '~/layout_nav';

/**
 * Given an array of tabs, renders non linked bootstrap tabs.
 * When a tab is clicked it will trigger an event and provide the clicked scope.
 *
 * This component is used in apps that handle the API call.
 * If you only need to change the URL this component should not be used.
 *
 * @example
 * <navigation-tabs
 *   :tabs="[
 *   {
 *      name: String,
 *      scope: String,
 *      count: Number || Undefined || Null,
 *      isActive: Boolean,
 *    },
 *   ]"
 *   @onChangeTab="onChangeTab"
 *   />
 */
export default {
  name: 'NavigationTabs',
  components: {
    GlBadge,
    GlTabs,
    GlTab,
  },
  props: {
    tabs: {
      type: Array,
      required: true,
    },
    scope: {
      type: String,
      required: false,
      default: '',
    },
  },
  mounted() {
    initScrollingTabs();
  },
  methods: {
    shouldRenderBadge(count) {
      // 0 is valid in a badge, but evaluates to false, we need to check for undefined or null
      return !(count === undefined || count === null);
    },

    onTabClick(tab) {
      this.$emit('onChangeTab', tab.scope);
    },
  },
};
</script>
<template>
  <gl-tabs class="gl-flex gl-w-full" nav-class="!gl-border-0">
    <gl-tab
      v-for="(tab, i) in tabs"
      :key="i"
      :title-link-class="`js-${scope}-tab-${tab.scope} gl-inline-flex`"
      :title-link-attributes="/* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ {
        'data-testid': `${scope}-tab-${tab.scope}`,
      } /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */"
      :active="tab.isActive"
      @click="onTabClick(tab)"
    >
      <template #title>
        <span class="gl-mr-2"> {{ tab.name }} </span>
        <gl-badge v-if="shouldRenderBadge(tab.count)" class="gl-tab-counter-badge">{{
          tab.count
        }}</gl-badge>
      </template>
    </gl-tab>
  </gl-tabs>
</template>
