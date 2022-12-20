<script>
import { GlCollapse } from '@gitlab/ui';
import { user, counts, context } from '../mock_data';
import UserBar from './user_bar.vue';
import ContextSwitcherToggle from './context_switcher_toggle.vue';
import ContextSwitcher from './context_switcher.vue';
import BottomBar from './bottom_bar.vue';

export default {
  context,
  user,
  counts,
  components: {
    GlCollapse,
    UserBar,
    ContextSwitcherToggle,
    ContextSwitcher,
    BottomBar,
  },
  data() {
    return {
      contextSwitcherOpened: false,
    };
  },
};
</script>

<template>
  <aside
    class="super-sidebar gl-fixed gl-bottom-0 gl-left-0 gl-display-flex gl-flex-direction-column gl-bg-gray-10 gl-border-r gl-border-gray-a-08 gl-z-index-9999"
    data-testid="super-sidebar"
  >
    <user-bar :user="$options.user" :counts="$options.counts" />
    <div class="gl-display-flex gl-flex-direction-column gl-flex-grow-1 gl-overflow-hidden">
      <div class="gl-flex-grow-1 gl-overflow-auto">
        <context-switcher-toggle :context="$options.context" :expanded="contextSwitcherOpened" />
        <gl-collapse id="context-switcher" v-model="contextSwitcherOpened">
          <context-switcher />
        </gl-collapse>
      </div>
      <div class="gl-px-3">
        <bottom-bar />
      </div>
    </div>
  </aside>
</template>
