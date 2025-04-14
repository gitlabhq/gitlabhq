<script>
import { GlAlert } from '@gitlab/ui';
import Stacktrace from '~/error_tracking/components/stacktrace.vue';
import { __ } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import workItemErrorTrackingQuery from '../graphql/work_item_error_tracking.query.graphql';
import { findErrorTrackingWidget } from '../utils';

const POLL_INTERVAL = 2000;

export default {
  components: {
    CrudComponent,
    GlAlert,
    Stacktrace,
  },
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    iid: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      errorMessage: '',
      errorTracking: {},
      loading: false,
    };
  },
  apollo: {
    errorTracking: {
      query: workItemErrorTrackingQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          iid: this.iid,
        };
      },
      update(data) {
        return findErrorTrackingWidget(data.namespace.workItem) ?? {};
      },
      error(error) {
        this.errorMessage = __('Failed to load stack trace.');
        Sentry.captureException(error);
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.errorTracking.loading || this.loading;
    },
    stackTrace() {
      return this.errorTracking.stackTrace?.nodes.toReversed() ?? [];
    },
    status() {
      return this.errorTracking.status;
    },
  },
  watch: {
    // The backend fetches data in the background, so the data won't be available immediately.
    // The backend returns 'RETRY' until it receives data so we need to keep polling until then.
    status(status) {
      switch (status) {
        case 'RETRY':
          this.$apollo.queries.errorTracking.startPolling(POLL_INTERVAL);
          this.loading = true;
          break;
        case 'NOT_FOUND':
          this.errorMessage = __('Sentry issue not found.');
          this.stopPolling();
          break;
        case 'ERROR':
          this.errorMessage = __('Error tracking service responded with an error.');
          this.stopPolling();
          break;
        case 'SUCCESS':
          this.stopPolling();
          break;
        default:
          this.stopPolling();
      }
    },
  },
  beforeDestroy() {
    // Stop polling, for example when closing a work item drawer
    this.stopPolling();
  },
  methods: {
    stopPolling() {
      this.$apollo.queries.errorTracking.stopPolling();
      this.loading = false;
    },
  },
};
</script>

<template>
  <crud-component
    anchor-id="stack-trace"
    is-collapsible
    :is-loading="isLoading"
    persist-collapsed-state
    :title="__('Stack trace')"
  >
    <template #default>
      <gl-alert v-if="errorMessage" :dismissible="false" variant="danger">
        {{ errorMessage }}
      </gl-alert>
      <stacktrace v-if="stackTrace.length" :entries="stackTrace" />
    </template>
  </crud-component>
</template>
