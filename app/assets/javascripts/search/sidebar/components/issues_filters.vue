<script>
import { GlButton, GlLink } from '@gitlab/ui';
import { mapActions, mapState, mapGetters } from 'vuex';
import Tracking from '~/tracking';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import {
  HR_DEFAULT_CLASSES,
  TRACKING_ACTION_CLICK,
  TRACKING_LABEL_APPLY,
  TRACKING_CATEGORY,
  TRACKING_LABEL_RESET,
} from '../constants/index';
import { confidentialFilterData } from './confidentiality_filter/data';
import { statusFilterData } from './status_filter/data';
import ConfidentialityFilter from './confidentiality_filter/index.vue';
import { labelFilterData } from './label_filter/data';
import LabelFilter from './label_filter/index.vue';
import StatusFilter from './status_filter/index.vue';

export default {
  name: 'IssuesFilters',
  components: {
    GlButton,
    GlLink,
    StatusFilter,
    ConfidentialityFilter,
    LabelFilter,
  },
  mixins: [glFeatureFlagsMixin()],
  computed: {
    ...mapState(['urlQuery', 'sidebarDirty', 'useNewNavigation']),
    ...mapGetters(['currentScope']),
    showReset() {
      return this.urlQuery.state || this.urlQuery.confidential || this.urlQuery.labels;
    },
    showConfidentialityFilter() {
      return Object.values(confidentialFilterData.scopes).includes(this.currentScope);
    },
    showStatusFilter() {
      return Object.values(statusFilterData.scopes).includes(this.currentScope);
    },
    showLabelFilter() {
      return (
        Object.values(labelFilterData.scopes).includes(this.currentScope) &&
        this.glFeatures.searchIssueLabelAggregation
      );
    },
    hrClasses() {
      return [...HR_DEFAULT_CLASSES, 'gl-display-none', 'gl-md-display-block'];
    },
  },
  methods: {
    ...mapActions(['applyQuery', 'resetQuery']),
    applyQueryWithTracking() {
      Tracking.event(TRACKING_ACTION_CLICK, TRACKING_LABEL_APPLY, {
        label: TRACKING_CATEGORY,
      });
      this.applyQuery();
    },
    resetQueryWithTracking() {
      Tracking.event(TRACKING_ACTION_CLICK, TRACKING_LABEL_RESET, {
        label: TRACKING_CATEGORY,
      });
      this.resetQuery();
    },
  },
};
</script>

<template>
  <form class="issue-filters gl-px-5 gl-pt-0" @submit.prevent="applyQueryWithTracking">
    <hr v-if="!useNewNavigation" :class="hrClasses" />
    <status-filter v-if="showStatusFilter" class="gl-mb-5" />
    <hr v-if="!useNewNavigation" :class="hrClasses" />
    <confidentiality-filter v-if="showConfidentialityFilter" class="gl-mb-5" />
    <hr
      v-if="!useNewNavigation && showConfidentialityFilter && showLabelFilter"
      :class="hrClasses"
    />
    <label-filter v-if="showLabelFilter" />
    <div class="gl-display-flex gl-align-items-center gl-mt-4">
      <gl-button category="primary" variant="confirm" type="submit" :disabled="!sidebarDirty">
        {{ __('Apply') }}
      </gl-button>
      <gl-link v-if="showReset" class="gl-ml-auto" @click="resetQueryWithTracking">{{
        __('Reset filters')
      }}</gl-link>
    </div>
  </form>
</template>
