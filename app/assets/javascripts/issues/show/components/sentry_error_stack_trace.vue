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
    ...mapState('details', ['loadingStacktrace', 'stacktraceData']),
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
    <div :class="{ 'border-bottom-0': loadingStacktrace }" class="card card-slim mt-4 mb-0">
      <div class="card-header border-bottom-0">
        <h5 class="card-title my-1">{{ __('Stack trace') }}</h5>
      </div>
    </div>
    <div v-if="loadingStacktrace" class="card">
      <gl-loading-icon class="py-2" label="Fetching stack trace" size="sm" />
    </div>
    <stacktrace v-else :entries="stacktrace" />
  </div>
</template>
