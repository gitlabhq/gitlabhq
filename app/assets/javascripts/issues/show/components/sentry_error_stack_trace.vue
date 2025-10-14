<script>
import { GlLoadingIcon } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState, mapGetters } from 'vuex';
import Stacktrace from '~/error_tracking/components/stacktrace.vue';

export default {
  name: 'SentryErrorStackTrace',
  components: {
    Stacktrace,
    GlLoadingIcon,
  },
  props: {
    issueStackTracePath: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState('details', ['loadingStacktrace']),
    ...mapGetters('details', ['stacktrace']),
  },
  mounted() {
    this.startPollingStacktrace(this.issueStackTracePath);
  },
  methods: {
    ...mapActions('details', ['startPollingStacktrace']),
  },
};
</script>

<template>
  <div>
    <div :class="{ '!gl-border-b-0': loadingStacktrace }" class="card card-slim !gl-mb-0 !gl-mt-6">
      <div class="card-header !gl-border-b-0">
        <h5 class="card-title !gl-my-2">{{ __('Stack trace') }}</h5>
      </div>
    </div>
    <div v-if="loadingStacktrace" class="card">
      <gl-loading-icon class="!gl-py-3" label="Fetching stack trace" size="sm" />
    </div>
    <stacktrace v-else :entries="stacktrace" />
  </div>
</template>
