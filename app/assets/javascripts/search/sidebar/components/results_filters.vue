<script>
import { GlButton, GlLink } from '@gitlab/ui';
import { mapActions, mapState, mapGetters } from 'vuex';
import { HR_DEFAULT_CLASSES } from '../constants/index';
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
  computed: {
    ...mapState(['urlQuery', 'sidebarDirty', 'useNewNavigation']),
    ...mapGetters(['currentScope']),
    showReset() {
      return this.urlQuery.state || this.urlQuery.confidential;
    },
    showConfidentialityFilter() {
      return Object.values(confidentialFilterData.scopes).includes(this.currentScope);
    },
    showStatusFilter() {
      return Object.values(stateFilterData.scopes).includes(this.currentScope);
    },
    hrClasses() {
      return [...HR_DEFAULT_CLASSES, 'gl-display-none', 'gl-md-display-block'];
    },
  },
  methods: {
    ...mapActions(['applyQuery', 'resetQuery']),
  },
};
</script>

<template>
  <form class="gl-pt-5 gl-md-pt-0" @submit.prevent="applyQuery">
    <hr v-if="!useNewNavigation" :class="hrClasses" />
    <status-filter v-if="showStatusFilter" />
    <confidentiality-filter v-if="showConfidentialityFilter" />
    <div class="gl-display-flex gl-align-items-center gl-mt-4 gl-px-5">
      <gl-button category="primary" variant="confirm" type="submit" :disabled="!sidebarDirty">
        {{ __('Apply') }}
      </gl-button>
      <gl-link v-if="showReset" class="gl-ml-auto" @click="resetQuery">{{
        __('Reset filters')
      }}</gl-link>
    </div>
  </form>
</template>
