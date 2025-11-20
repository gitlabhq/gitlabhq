<script>
import {
  GlCard,
  GlButton,
  GlBadge,
  GlSkeletonLoader,
  GlAlert,
  GlKeysetPagination,
  GlTooltipDirective,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import { untrackRefsOptimisticResponse, updateUntrackedRefsCache } from '../graphql/cache_utils';
import securityTrackedRefs from '../graphql/security_tracked_refs.query.graphql';
import untrackSecurityTrackedRefsMutation from '../graphql/untrack_security_tracked_refs.mutation.graphql';
import trackSecurityTrackedRefsMutation from '../graphql/track_security_tracked_refs.mutation.graphql';
import RefTrackingListItem from './ref_tracking_list_item.vue';
import RefUntrackingConfirmation from './ref_untracking_confirmation.vue';
import RefTrackingSelection from './ref_tracking_selection.vue';

export const MAX_TRACKED_REFS = 3;

export default {
  components: {
    GlAlert,
    GlCard,
    GlButton,
    GlBadge,
    GlSkeletonLoader,
    GlKeysetPagination,
    RefTrackingListItem,
    RefUntrackingConfirmation,
    RefTrackingSelection,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['projectFullPath'],
  apollo: {
    trackedRefs: {
      query: securityTrackedRefs,
      variables() {
        const { after, before } = this.pageCursor;

        return {
          fullPath: this.projectFullPath,
          first: before ? null : MAX_TRACKED_REFS,
          last: before ? MAX_TRACKED_REFS : null,
          after,
          before,
        };
      },
      update(data) {
        return data.project.securityTrackedRefs.nodes || [];
      },
      result({ data }) {
        if (data) {
          const { pageInfo, count } = data.project.securityTrackedRefs;

          this.pageInfo = pageInfo;
          this.totalCount = count;
        }
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
      hasTrackError: false,
      isTrackingRefs: false,
      totalCount: null,
      pageCursor: {
        after: null,
        before: null,
      },
      pageInfo: {},
      showTrackingSelection: false,
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.trackedRefs.loading;
    },
    hasPreviousPage() {
      return Boolean(this.pageInfo.hasPreviousPage);
    },
    hasNextPage() {
      return Boolean(this.pageInfo.hasNextPage);
    },
    showPagination() {
      return this.hasPreviousPage || this.hasNextPage;
    },
    hasMaxTrackedRefs() {
      return this.totalCount >= this.$options.MAX_TRACKED_REFS;
    },
    shouldDisableTrackNewRefButton() {
      return this.isLoading || this.isTrackingRefs || this.hasMaxTrackedRefs;
    },
    trackNewRefButtonTooltip() {
      if (this.isLoading) {
        return s__('SecurityTrackedRefs|Loading tracked refs. Please wait.');
      }

      if (this.isTrackingRefs) {
        return s__('SecurityTrackedRefs|Tracking refs in progress. Please wait.');
      }

      if (this.hasMaxTrackedRefs) {
        return s__(
          'SecurityTrackedRefs|Maximum number of tracked refs reached. Remove a ref to track a new one.',
        );
      }
      return '';
    },
  },
  methods: {
    async trackRefs(selectedRefs) {
      this.showTrackingSelection = false;
      this.isTrackingRefs = true;

      try {
        const refs = selectedRefs.map((ref) => ({
          name: ref.name,
          refType: ref.refType,
          isProtected: ref.isProtected,
          commit: ref.commit,
        }));

        const { data } = await this.$apollo.mutate({
          mutation: trackSecurityTrackedRefsMutation,
          variables: {
            input: {
              projectPath: this.projectFullPath,
              refs,
            },
          },
          refetchQueries: [
            {
              query: securityTrackedRefs,
              variables: { fullPath: this.projectFullPath },
            },
          ],
          awaitRefetchQueries: true,
        });

        if (data.securityTrackedRefsTrack.errors?.length) {
          throw new Error();
        }
      } catch {
        this.hasTrackError = true;
        this.errorMessage = s__(
          'SecurityTrackedRefs|Could not track refs. Please refresh the page, or try again later.',
        );
      } finally {
        this.isTrackingRefs = false;
      }
    },
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
          'SecurityTrackedRefs|Could not remove tracked ref. Please refresh the page, or try again later.',
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
    goToNextPage() {
      this.pageCursor.after = this.pageInfo.endCursor;
      this.pageCursor.before = null;
    },
    goToPreviousPage() {
      this.pageCursor.before = this.pageInfo.startCursor;
      this.pageCursor.after = null;
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
            {{ s__('SecurityTrackedRefs|Currently tracked refs') }}
          </h3>
          <gl-badge variant="neutral"
            >{{ totalCount === null ? '-' : totalCount }}/{{ $options.MAX_TRACKED_REFS }}</gl-badge
          >
        </div>
        <span
          v-gl-tooltip
          :title="trackNewRefButtonTooltip"
          data-testid="track-new-ref-button-tooltip"
        >
          <gl-button
            variant="confirm"
            size="small"
            :disabled="shouldDisableTrackNewRefButton"
            @click="showTrackingSelection = true"
            >{{ s__('SecurityTrackedRefs|Track new ref(s)') }}</gl-button
          >
        </span>
      </div>
    </template>

    <gl-alert
      v-if="hasFetchError || hasUntrackError || hasTrackError"
      variant="danger"
      :dismissible="hasUntrackError || hasTrackError"
      @dismiss="
        hasUntrackError = false;
        hasTrackError = false;
      "
    >
      {{ errorMessage }}
    </gl-alert>

    <div v-if="isLoading || isTrackingRefs" class="gl-px-4 gl-py-6">
      <gl-skeleton-loader v-for="i in 4" :key="i" :width="600" :height="35">
        <rect width="100" height="8" x="0" y="0" rx="4" />
        <rect width="100" height="8" x="500" y="0" rx="4" />
        <rect width="450" height="8" x="0" y="20" rx="4" />
      </gl-skeleton-loader>
    </div>

    <ul
      v-if="!isLoading && !isTrackingRefs && !hasFetchError"
      class="gl-m-0 gl-list-none gl-p-0"
      data-testid="tracked-refs-list"
    >
      <ref-tracking-list-item
        v-for="ref in trackedRefs"
        :key="ref.id"
        :tracked-ref="ref"
        class="gl-min-h-[5rem]"
        @untrack="openUntrackConfirmation"
      />
    </ul>

    <template v-if="showPagination" #footer>
      <gl-keyset-pagination
        :has-previous-page="pageInfo.hasPreviousPage"
        :has-next-page="pageInfo.hasNextPage"
        :start-cursor="pageInfo.startCursor"
        :end-cursor="pageInfo.endCursor"
        class="gl-flex gl-items-center gl-justify-center"
        data-testid="pagination-controls"
        @prev="goToPreviousPage"
        @next="goToNextPage"
      />
    </template>

    <ref-untracking-confirmation
      :ref-to-untrack="refToUntrack"
      @confirm="untrackRef"
      @cancel="closeUntrackConfirmation"
    />

    <ref-tracking-selection
      v-if="showTrackingSelection"
      :tracked-refs="trackedRefs"
      :max-tracked-refs="$options.MAX_TRACKED_REFS"
      @select="trackRefs"
      @cancel="showTrackingSelection = false"
    />
  </gl-card>
</template>
