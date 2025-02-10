<script>
import { GlButton, GlForm } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState, mapGetters } from 'vuex';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import Tracking from '~/tracking';

import {
  SEARCH_TYPE_ZOEKT,
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
  mixins: [glFeatureFlagsMixin()],
  computed: {
    ...mapState(['sidebarDirty', 'searchType']),
    ...mapGetters(['currentScope', 'hasMissingProjectContext']),
    showApplyButton() {
      return !(
        this.searchType === SEARCH_TYPE_ZOEKT &&
        this.glFeatures?.zoektMultimatchFrontend &&
        this.hasMissingProjectContext &&
        this.currentScope === 'blobs'
      );
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
  <gl-form
    class="issue-filters gl-px-4 gl-pt-0"
    :aria-label="__('Search filters')"
    @submit.prevent="applyQueryWithTracking"
  >
    <slot></slot>
    <div class="gl-mt-4 gl-flex gl-items-center">
      <gl-button
        v-if="showApplyButton"
        category="primary"
        variant="confirm"
        type="submit"
        data-testid="search-apply-filters-btn"
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
