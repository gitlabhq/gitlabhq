<script>
import { GlButton, GlForm } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState, mapGetters } from 'vuex';
import Tracking from '~/tracking';

import {
  TRACKING_ACTION_CLICK,
  TRACKING_LABEL_APPLY,
  TRACKING_LABEL_RESET,
} from '../constants/index';

export default {
  name: 'FiltersTemplate',
  components: {
    GlButton,
    GlForm,
  },
  computed: {
    ...mapState(['sidebarDirty']),
    ...mapGetters(['currentScope']),
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
  <gl-form
    class="issue-filters gl-px-5 gl-pt-0"
    :aria-label="__('Search filters')"
    @submit.prevent="applyQueryWithTracking"
  >
    <slot></slot>
    <div class="gl-display-flex gl-align-items-center gl-mt-4">
      <gl-button
        category="primary"
        variant="confirm"
        type="submit"
        data-testid="search-apply-filters-btn"
        :disabled="!sidebarDirty"
      >
        {{ __('Apply') }}
      </gl-button>
      <gl-button
        v-if="sidebarDirty"
        category="tertiary"
        class="gl-ml-auto"
        data-testid="search-reset-filters-btn"
        @click="resetQueryWithTracking"
        >{{ __('Reset filters') }}
      </gl-button>
    </div>
  </gl-form>
</template>
