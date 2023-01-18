<script>
import { GlButton, GlLink } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { confidentialFilterData } from '../constants/confidential_filter_data';
import { stateFilterData } from '../constants/state_filter_data';
import ConfidentialityFilter from './confidentiality_filter.vue';
import StatusFilter from './status_filter.vue';

export default {
  name: 'ResultsFilters',
  components: {
    GlButton,
    GlLink,
    StatusFilter,
    ConfidentialityFilter,
  },
  mixins: [glFeatureFlagsMixin()],
  computed: {
    ...mapState(['urlQuery', 'sidebarDirty']),
    showReset() {
      return this.urlQuery.state || this.urlQuery.confidential;
    },
    searchPageVerticalNavFeatureFlag() {
      return this.glFeatures.searchPageVerticalNav;
    },
    showConfidentialityFilter() {
      return Object.values(confidentialFilterData.scopes).includes(this.urlQuery.scope);
    },
    showStatusFilter() {
      return Object.values(stateFilterData.scopes).includes(this.urlQuery.scope);
    },
    ffBasedXPadding() {
      return this.glFeatures.searchPageVerticalNav ? 'gl-px-5' : 'gl-px-0';
    },
  },
  methods: {
    ...mapActions(['applyQuery', 'resetQuery']),
  },
};
</script>

<template>
  <form class="gl-pt-5 gl-md-pt-0" @submit.prevent="applyQuery">
    <hr
      v-if="searchPageVerticalNavFeatureFlag"
      class="gl-my-5 gl-mx-5 gl-border-gray-100 gl-display-none gl-md-display-block"
    />
    <status-filter v-if="showStatusFilter" />
    <confidentiality-filter v-if="showConfidentialityFilter" />
    <div class="gl-display-flex gl-align-items-center gl-mt-4" :class="ffBasedXPadding">
      <gl-button category="primary" variant="confirm" type="submit" :disabled="!sidebarDirty">
        {{ __('Apply') }}
      </gl-button>
      <gl-link v-if="showReset" class="gl-ml-auto" @click="resetQuery">{{
        __('Reset filters')
      }}</gl-link>
    </div>
  </form>
</template>
