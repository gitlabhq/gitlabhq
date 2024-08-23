<script>
import { GlEmptyState, GlButton } from '@gitlab/ui';
import noReviewersAssignedSvg from '@gitlab/svgs/dist/illustrations/add-user-sm.svg?url';
import UncollapsedReviewerList from '~/sidebar/components/reviewers/uncollapsed_reviewer_list.vue';
import { sprintf, __, n__ } from '~/locale';
import ReviewerDropdown from '~/merge_requests/components/reviewers/reviewer_dropdown.vue';
import UpdateReviewers from './update_reviewers.vue';
import userPermissionsQuery from './queries/user_permissions.query.graphql';

export default {
  apollo: {
    userPermissions: {
      query: userPermissionsQuery,
      variables() {
        return {
          fullPath: this.projectPath,
          iid: this.issuableIid,
        };
      },
      update: (data) => data.project?.mergeRequest?.userPermissions || {},
    },
  },
  components: {
    GlEmptyState,
    GlButton,
    UncollapsedReviewerList,
    UpdateReviewers,
    ReviewerDropdown,
  },
  inject: ['projectPath', 'issuableIid'],
  props: {
    reviewers: {
      type: Array,
      required: true,
    },
    loadingReviewers: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      userPermissions: {},
    };
  },
  computed: {
    currentUser() {
      return [gon.current_username];
    },
    relativeUrlRoot() {
      return gon.relative_url_root ?? '';
    },
    reviewersTitle() {
      if (this.reviewers.length === 0) {
        return sprintf(__('%{count} Reviewers'), { count: this.reviewers.length });
      }

      return sprintf(n__('%{count} Reviewer', '%{count} Reviewers', this.reviewers.length), {
        count: this.reviewers.length,
      });
    },
  },
  noReviewersAssignedSvg,
};
</script>

<template>
  <div>
    <div class="gl-mb-3 gl-flex gl-w-full gl-items-center gl-font-bold gl-leading-20">
      <template v-if="loadingReviewers">
        <div class="gl-animate-skeleton-loader gl-h-4 gl-w-20 gl-rounded-base"></div>
        <div class="gl-animate-skeleton-loader gl-ml-auto gl-h-4 gl-w-4 gl-rounded-base"></div>
      </template>
      <template v-else>
        {{ reviewersTitle }}
        <reviewer-dropdown :selected-reviewers="reviewers" class="gl-ml-auto" />
      </template>
    </div>
    <div v-if="loadingReviewers">
      <div class="gl-animate-skeleton-loader gl-mb-3 gl-h-4 !gl-max-w-20 gl-rounded-base"></div>
      <div class="gl-animate-skeleton-loader gl-mb-3 gl-h-4 !gl-max-w-20 gl-rounded-base"></div>
      <div class="gl-animate-skeleton-loader gl-h-4 !gl-max-w-20 gl-rounded-base"></div>
    </div>
    <uncollapsed-reviewer-list
      v-else-if="reviewers.length"
      :root-path="relativeUrlRoot"
      :users="reviewers"
      issuable-type="merge_request"
      @request-review="(params) => $emit('request-review', params)"
    />
    <gl-empty-state v-else :svg-path="$options.noReviewersAssignedSvg" :svg-height="70">
      <template #description>
        <p class="gl-mb-3 gl-font-normal">{{ __('No reviewers assigned') }}</p>
        <update-reviewers
          v-if="userPermissions.adminMergeRequest"
          :selected-reviewers="currentUser"
        >
          <template #default="{ loading, updateReviewers }">
            <gl-button
              category="tertiary"
              size="small"
              :loading="loading"
              data-testid="assign-yourself-button"
              @click="updateReviewers"
            >
              {{ __('Assign yourself') }}
            </gl-button>
          </template>
        </update-reviewers>
      </template>
    </gl-empty-state>
  </div>
</template>
