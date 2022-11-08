<script>
import { GlButton, GlLink } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
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
  },
  methods: {
    ...mapActions(['applyQuery', 'resetQuery']),
  },
};
</script>

<template>
  <form
    :class="searchPageVerticalNavFeatureFlag ? 'gl-px-5' : 'gl-px-0'"
    @submit.prevent="applyQuery"
  >
    <hr v-if="searchPageVerticalNavFeatureFlag" class="gl-my-5 gl-border-gray-100" />
    <status-filter />
    <confidentiality-filter />
    <div class="gl-display-flex gl-align-items-center gl-mt-4">
      <gl-button category="primary" variant="confirm" type="submit" :disabled="!sidebarDirty">
        {{ __('Apply') }}
      </gl-button>
      <gl-link v-if="showReset" class="gl-ml-auto" @click="resetQuery">{{
        __('Reset filters')
      }}</gl-link>
    </div>
  </form>
</template>
