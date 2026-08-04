<script>
import {
  GlCard,
  GlButton,
  GlBadge,
  GlSkeletonLoader,
  GlAlert,
  GlKeysetPagination,
  GlLink,
  GlPopover,
  GlTooltipDirective,
} from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { untrackRefsOptimisticResponse, updateUntrackedRefsCache } from '../graphql/cache_utils';
import securityTrackedRefs from '../graphql/security_tracked_refs.query.graphql';
import untrackSecurityRefsMutation from '../graphql/untrack_security_refs.mutation.graphql';
import trackSecurityRefsMutation from '../graphql/track_security_refs.mutation.graphql';
import RefTrackingListItem from './ref_tracking_list_item.vue';
import RefUntrackingConfirmation from './ref_untracking_confirmation.vue';
import RefTrackingSelection from './ref_tracking_selection.vue';

export default {
  name: 'RefTrackingList',
  components: {
    GlAlert,
    GlCard,
    GlButton,
    GlBadge,
    GlSkeletonLoader,
    GlKeysetPagination,
    GlLink,
    GlPopover,
    RefTrackingListItem,
    RefUntrackingConfirmation,
    RefTrackingSelection,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  betaHelpPath: helpPagePath('user/application_security/vulnerability_report/_index.md'),
  mixins: [glFeatureFlagMixin()],
  inject: ['projectFullPath', 'maxTrackedRefs'],
  apollo: {
    trackedRefs: {
      query: securityTrackedRefs,
      variables() {
        return this.trackedRefsQueryVariables;
      },
      update(data) {
        return data.project?.securityTrackedRefs?.nodes || [];
      },
      result({ data }) {
        if (data?.project?.securityTrackedRefs) {
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
    trackedRefsQueryVariables() {
      const { after, before } = this.pageCursor;

      return {
        fullPath: this.projectFullPath,
        first: before ? null : this.maxTrackedRefs,
        last: before ? this.maxTrackedRefs : null,
        after,
        before,
      };
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
      return this.totalCount >= this.maxTrackedRefs;
    },
    showBeta() {
      return Boolean(this.glFeatures?.vulnerabilitiesAcrossContexts);
    },
    betaPopoverDescription() {
      return sprintf(
        s__(
          "SecurityTrackedRefs|You can now track vulnerabilities on refs other than the default branch. During Beta, you're limited to %{limit} refs per project, but we'll expand this and add more capabilities over time.",
        ),
        { limit: this.maxTrackedRefs },
      );
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
        }));

        const { data } = await this.$apollo.mutate({
          mutation: trackSecurityRefsMutation,
          variables: {
            input: {
              projectPath: this.projectFullPath,
              refs,
            },
          },
        });

        if (data.securityRefsTrack.errors?.length) {
          throw new Error();
        }

        try {
          await this.$apollo.queries.trackedRefs.refetch();
        } catch {
          throw new Error(
            s__(
              'SecurityTrackedRefs|Refs were tracked successfully but the list could not be refreshed. Please refresh the page.',
            ),
          );
        }
      } catch (e) {
        this.hasTrackError = true;
        this.errorMessage =
          e?.message ||
          s__(
            'SecurityTrackedRefs|Could not track refs. Please refresh the page, or try again later.',
          );
      } finally {
        this.isTrackingRefs = false;
      }
    },
    async untrackRef({ refId }) {
      try {
        const { data } = await this.$apollo.mutate({
          mutation: untrackSecurityRefsMutation,
          variables: {
            input: {
              refIds: [refId],
            },
          },
          optimisticResponse: untrackRefsOptimisticResponse([refId]),
          update: updateUntrackedRefsCache({
            query: securityTrackedRefs,
            variables: this.trackedRefsQueryVariables,
          }),
        });

        if (data.securityRefsUntrack.errors?.length) {
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
            >{{ totalCount === null ? '-' : totalCount }}/{{ maxTrackedRefs }}</gl-badge
          >
          <template v-if="showBeta">
            <gl-badge
              id="tracked-refs-beta-badge"
              variant="neutral"
              class="hover:gl-cursor-pointer"
              data-testid="tracked-refs-beta-badge"
              >{{ s__('SecurityTrackedRefs|Beta') }}</gl-badge
            >
            <gl-popover
              target="tracked-refs-beta-badge"
              triggers="hover focus click"
              placement="bottom"
              show-close-button
              :title="s__('SecurityTrackedRefs|Track vulnerabilities across refs (Beta)')"
              data-testid="tracked-refs-beta-popover"
            >
              <p class="gl-mb-3">{{ betaPopoverDescription }}</p>
              <gl-link :href="$options.betaHelpPath" target="_blank">{{
                s__('SecurityTrackedRefs|What can I expect after Beta?')
              }}</gl-link>
            </gl-popover>
          </template>
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
      :max-tracked-refs="maxTrackedRefs"
      @select="trackRefs"
      @cancel="showTrackingSelection = false"
    />
  </gl-card>
</template>
