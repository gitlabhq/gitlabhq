<script>
import { GlDrawer } from '@gitlab/ui';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import getMergeRequestReviewers from '~/sidebar/queries/get_merge_request_reviewers.query.graphql';

export default {
  apollo: {
    reviewers: {
      query: getMergeRequestReviewers,
      variables() {
        return {
          fullPath: this.projectPath,
          iid: this.issuableIid,
        };
      },
      update: (data) => data.workspace?.issuable?.reviewers?.nodes || [],
      skip() {
        return !this.open;
      },
    },
  },
  components: {
    GlDrawer,
    ApprovalSummary: () =>
      import('ee_component/merge_requests/components/reviewers/approval_summary.vue'),
    ApprovalRulesWrapper: () =>
      import('ee_component/merge_requests/components/reviewers/approval_rules_wrapper.vue'),
  },
  inject: ['projectPath', 'issuableIid'],
  props: {
    open: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      reviewers: [],
    };
  },
  computed: {
    getDrawerHeaderHeight() {
      if (!this.open) return '0';
      return getContentWrapperHeight();
    },
    loadingReviewers() {
      return this.$apollo.queries.reviewers.loading;
    },
  },
  DRAWER_Z_INDEX,
};
</script>

<template>
  <gl-drawer
    :header-height="getDrawerHeaderHeight"
    :z-index="$options.DRAWER_Z_INDEX"
    :open="open"
    @close="$emit('close')"
  >
    <template #title>
      <h4 class="gl-my-0">{{ __('Assign reviewers') }}</h4>
    </template>
    <template #header>
      <approval-summary class="gl-mt-3" />
    </template>
    <approval-rules-wrapper
      :reviewers="reviewers"
      @request-review="(data) => $emit('request-review', data)"
      @remove-reviewer="(data) => $emit('remove-reviewer', data)"
    />
  </gl-drawer>
</template>
