<script>
import { mapActions, mapState } from 'vuex';
import { GlButton, GlLink } from '@gitlab/ui';
import StatusFilter from './status_filter.vue';
import ConfidentialityFilter from './confidentiality_filter.vue';

export default {
  name: 'GlobalSearchSidebar',
  components: {
    GlButton,
    GlLink,
    StatusFilter,
    ConfidentialityFilter,
  },
  computed: {
    ...mapState(['query']),
    showReset() {
      return this.query.state || this.query.confidential;
    },
  },
  methods: {
    ...mapActions(['applyQuery', 'resetQuery']),
  },
};
</script>

<template>
  <form
    class="gl-display-flex gl-flex-direction-column col-md-3 gl-mr-4 gl-mb-6 gl-mt-5"
    @submit.prevent="applyQuery"
  >
    <status-filter />
    <confidentiality-filter />
    <div class="gl-display-flex gl-align-items-center gl-mt-3">
      <gl-button variant="success" type="submit">{{ __('Apply') }}</gl-button>
      <gl-link v-if="showReset" class="gl-ml-auto" @click="resetQuery">{{
        __('Reset filters')
      }}</gl-link>
    </div>
  </form>
</template>
