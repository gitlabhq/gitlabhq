<script>
import { GlButton, GlLink, GlForm } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState, mapGetters } from 'vuex';
import Tracking from '~/tracking';

import {
  HR_DEFAULT_CLASSES,
  TRACKING_ACTION_CLICK,
  TRACKING_LABEL_APPLY,
  TRACKING_LABEL_RESET,
} from '../constants/index';

export default {
  name: 'FiltersTemplate',
  components: {
    GlButton,
    GlLink,
    GlForm,
  },
  computed: {
    ...mapState(['sidebarDirty', 'useSidebarNavigation']),
    ...mapGetters(['currentScope']),
    hrClasses() {
      return [...HR_DEFAULT_CLASSES, 'gl-display-none', 'gl-md-display-block'];
    },
  },
  methods: {
    ...mapActions(['applyQuery', 'resetQuery']),
    applyQueryWithTracking() {
      Tracking.event(TRACKING_ACTION_CLICK, TRACKING_LABEL_APPLY, {
        label: this.currentScope,
      });
      this.applyQuery();
    },
    resetQueryWithTracking() {
      Tracking.event(TRACKING_ACTION_CLICK, TRACKING_LABEL_RESET, {
        label: this.currentScope,
      });
      this.resetQuery();
    },
  },
};
</script>

<template>
  <gl-form class="issue-filters gl-px-5 gl-pt-0" @submit.prevent="applyQueryWithTracking">
    <hr v-if="!useSidebarNavigation" :class="hrClasses" />
    <slot></slot>
    <hr v-if="!useSidebarNavigation" :class="hrClasses" />
    <div class="gl-display-flex gl-align-items-center gl-mt-4">
      <gl-button category="primary" variant="confirm" type="submit" :disabled="!sidebarDirty">
        {{ __('Apply') }}
      </gl-button>
      <gl-link v-if="sidebarDirty" class="gl-ml-auto" @click="resetQueryWithTracking">{{
        __('Reset filters')
      }}</gl-link>
    </div>
  </gl-form>
</template>
