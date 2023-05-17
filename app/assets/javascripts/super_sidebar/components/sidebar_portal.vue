<script>
import { MountingPortal } from 'portal-vue';
import { SIDEBAR_PORTAL_ID, portalState } from '../constants';

/**
 * Use this component to render content into the sidebar.
 *
 * Arbitrary content is allowed, but nav items should be added using a Ruby
 * Sidebars::Panel subclass instead.
 *
 * Only one instance of this component on a given page is supported. This is to
 * avoid ordering issues and cluttering the sidebar.
 */
export default {
  components: {
    MountingPortal,
  },
  data() {
    // This is shared state, by design. Do not mutate this state here.
    return portalState;
  },
  mountSelector: `#${SIDEBAR_PORTAL_ID}`,
};
</script>

<template>
  <mounting-portal v-if="ready" :mount-to="$options.mountSelector" append>
    <slot></slot>
  </mounting-portal>
</template>
