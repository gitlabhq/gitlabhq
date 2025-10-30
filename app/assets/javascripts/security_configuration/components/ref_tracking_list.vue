<script>
import { GlCard, GlButton, GlBadge, GlSkeletonLoader, GlAlert } from '@gitlab/ui';
import { s__ } from '~/locale';
import { untrackRefsOptimisticResponse, updateUntrackedRefsCache } from '../graphql/cache_utils';
import securityTrackedRefs from '../graphql/security_tracked_refs.query.graphql';
import untrackSecurityTrackedRefsMutation from '../graphql/untrack_security_tracked_refs.mutation.graphql';
import RefTrackingListItem from './ref_tracking_list_item.vue';
import RefUntrackingConfirmation from './ref_untracking_confirmation.vue';

export const MAX_TRACKED_REFS = 16;

export default {
  components: {
    GlAlert,
    GlCard,
    GlButton,
    GlBadge,
    GlSkeletonLoader,
    RefTrackingListItem,
    RefUntrackingConfirmation,
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
        this.hasFetchError = true;
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
      refToUntrack: null,
      hasFetchError: false,
      hasUntrackError: false,
    };
  },
  computed: {
    currentCount() {
      return this.trackedRefs.length;
    },
    isLoading() {
      return this.$apollo.queries.trackedRefs.loading;
    },
  },
  methods: {
    async untrackRef({ refId, archiveVulnerabilities }) {
      try {
        const { data } = await this.$apollo.mutate({
          mutation: untrackSecurityTrackedRefsMutation,
          variables: {
            input: {
              projectPath: this.projectFullPath,
              refIds: [refId],
              archiveVulnerabilities,
            },
          },
          optimisticResponse: untrackRefsOptimisticResponse([refId]),
          update: updateUntrackedRefsCache({
            query: securityTrackedRefs,
            variables: { fullPath: this.projectFullPath },
          }),
        });

        if (data.securityTrackedRefsUntrack.errors?.length) {
          throw new Error();
        }
      } catch {
        this.hasUntrackError = true;
        this.errorMessage = s__(
          'SecurityConfiguration|Could not remove tracked ref. Please refresh the page, or try again later.',
        );
      } finally {
        this.closeUntrackConfirmation();
      }
    },
    openUntrackConfirmation(ref) {
      this.refToUntrack = ref;
    },
    closeUntrackConfirmation() {
      this.refToUntrack = null;
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

    <gl-alert
      v-if="hasFetchError || hasUntrackError"
      variant="danger"
      :dismissible="hasUntrackError"
      @dismiss="hasUntrackError = false"
    >
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
        @untrack="openUntrackConfirmation"
      />
    </ul>
    <ref-untracking-confirmation
      :ref-to-untrack="refToUntrack"
      @confirm="untrackRef"
      @cancel="closeUntrackConfirmation"
    />
  </gl-card>
</template>
