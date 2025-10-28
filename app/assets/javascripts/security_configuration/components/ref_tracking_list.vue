<script>
import { GlCard, GlButton, GlBadge, GlSkeletonLoader, GlAlert } from '@gitlab/ui';
import { s__ } from '~/locale';
import securityTrackedRefs from '../graphql/security_tracked_refs.query.graphql';
import RefTrackingListItem from './ref_tracking_list_item.vue';

export const MAX_TRACKED_REFS = 16;

export default {
  components: {
    GlAlert,
    GlCard,
    GlButton,
    GlBadge,
    GlSkeletonLoader,
    RefTrackingListItem,
  },
  inject: ['projectFullPath'],
  apollo: {
    trackedRefs: {
      query: securityTrackedRefs,
      variables() {
        return {
          fullPath: this.projectFullPath,
        };
      },
      update(data) {
        return data.project?.securityTrackedRefs || [];
      },
      error() {
        this.errorMessage = s__(
          'SecurityConfiguration|Could not fetch tracked refs. Please refresh the page, or try again later.',
        );
      },
    },
  },
  data() {
    return {
      trackedRefs: [],
      errorMessage: '',
    };
  },
  computed: {
    currentCount() {
      return this.trackedRefs.length;
    },
    isLoading() {
      return this.$apollo.queries.trackedRefs.loading;
    },
    hasFetchError() {
      return Boolean(this.errorMessage);
    },
  },
  methods: {
    handleRemoveRef() {
      // The removal logic is handled in a separate issue
      // See https://gitlab.com/gitlab-org/gitlab/-/issues/577517
    },
  },
  MAX_TRACKED_REFS,
};
</script>

<template>
  <gl-card body-class="gl-p-0">
    <template #header>
      <div class="gl-flex gl-items-center gl-justify-between" data-testid="tracked-refs-header">
        <div class="gl-flex gl-items-center gl-gap-2">
          <h3 class="gl-my-0 gl-text-base" data-testid="tracked-refs-title">
            {{ __('Currently tracked refs') }}
          </h3>
          <gl-badge variant="neutral"
            >{{ isLoading || hasFetchError ? '-' : currentCount }}/{{
              $options.MAX_TRACKED_REFS
            }}</gl-badge
          >
        </div>
        <!-- The functionality to track new refs is handled in a separate issue -->
        <!-- See https://gitlab.com/gitlab-org/gitlab/-/issues/577515 -->
        <gl-button variant="confirm" size="small">{{ __('Track new ref') }}</gl-button>
      </div>
    </template>

    <gl-alert v-if="hasFetchError" variant="danger" :dismissible="false">
      {{ errorMessage }}
    </gl-alert>

    <div v-if="isLoading" class="gl-px-4 gl-py-6">
      <gl-skeleton-loader v-for="i in 4" :key="i" :width="600" :height="35">
        <rect width="100" height="8" x="0" y="0" rx="4" />
        <rect width="100" height="8" x="500" y="0" rx="4" />
        <rect width="450" height="8" x="0" y="20" rx="4" />
      </gl-skeleton-loader>
    </div>

    <ul
      v-if="!isLoading && !hasFetchError"
      class="gl-m-0 gl-list-none gl-p-0"
      data-testid="tracked-refs-list"
    >
      <ref-tracking-list-item
        v-for="ref in trackedRefs"
        :key="ref.id"
        :tracked-ref="ref"
        @remove="handleRemoveRef"
      />
    </ul>
  </gl-card>
</template>
