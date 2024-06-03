<script>
import { GlEmptyState, GlButton } from '@gitlab/ui';
import noReviewersAssignedSvg from '@gitlab/svgs/dist/illustrations/add-user-sm.svg?url';
import UncollapsedReviewerList from '~/sidebar/components/reviewers/uncollapsed_reviewer_list.vue';
import { sprintf, __, n__ } from '~/locale';
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
    <div class="gl-display-flex gl-mb-3">
      <template v-if="loadingReviewers">
        <div class="gl-animate-skeleton-loader gl-h-4 gl-rounded-base gl-w-20"></div>
        <div class="gl-animate-skeleton-loader gl-h-4 gl-rounded-base gl-w-2 gl-ml-auto"></div>
      </template>
      <div v-else class="gl-leading-20 gl-text-gray-900 gl-font-bold">
        {{ reviewersTitle }}
      </div>
    </div>
    <div v-if="loadingReviewers">
      <div class="gl-animate-skeleton-loader gl-h-4 gl-rounded-base gl-mb-3 gl-max-w-20!"></div>
      <div class="gl-animate-skeleton-loader gl-h-4 gl-rounded-base gl-mb-3 gl-max-w-20!"></div>
      <div class="gl-animate-skeleton-loader gl-h-4 gl-rounded-base gl-max-w-20!"></div>
    </div>
    <uncollapsed-reviewer-list
      v-else-if="reviewers.length"
      :root-path="relativeUrlRoot"
      :users="reviewers"
      issuable-type="merge_request"
    />
    <gl-empty-state v-else :svg-path="$options.noReviewersAssignedSvg" :svg-height="70">
      <template #description>
        <p class="gl-font-normal gl-mb-3">{{ __('No reviewers assigned') }}</p>
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
