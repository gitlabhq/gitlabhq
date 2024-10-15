<script>
// NOTE! For the first iteration, we are simply copying the implementation of Assignees
// It will soon be overhauled in Issue https://gitlab.com/gitlab-org/gitlab/-/issues/233736
import { GlLoadingIcon, GlButton, GlTooltipDirective } from '@gitlab/ui';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { n__, s__ } from '~/locale';
import ReviewerDropdown from '~/merge_requests/components/reviewers/reviewer_dropdown.vue';

export default {
  name: 'ReviewerTitle',
  components: {
    GlLoadingIcon,
    GlButton,
    ReviewerDropdown,
  },
  directives: {
    Tooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    numberOfReviewers: {
      type: Number,
      required: true,
    },
    editable: {
      type: Boolean,
      required: true,
    },
    reviewers: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    reviewerTitle() {
      const reviewers = this.numberOfReviewers;
      return n__('Reviewer', `%d Reviewers`, reviewers);
    },
  },
  i18n: {
    changeReviewer: s__('MergeRequest|Change reviewer'),
  },
};
</script>
<template>
  <div
    class="hide-collapsed gl-flex gl-items-center gl-gap-2 gl-font-bold gl-leading-20 gl-text-gray-900"
  >
    {{ reviewerTitle }}
    <gl-loading-icon v-if="loading" size="sm" inline class="align-bottom" />
    <template v-if="editable">
      <reviewer-dropdown
        v-if="glFeatures.reviewerAssignDrawer"
        class="gl-ml-auto"
        :selected-reviewers="reviewers"
      />
      <gl-button
        v-else
        v-tooltip.hover
        :title="$options.i18n.changeReviewer"
        class="hide-collapsed js-sidebar-dropdown-toggle edit-link gl-float-right gl-ml-auto"
        data-track-action="click_edit_button"
        data-track-label="right_sidebar"
        data-track-property="reviewer"
        data-testid="reviewers-edit-button"
        category="tertiary"
        size="small"
      >
        {{ __('Edit') }}
      </gl-button>
    </template>
  </div>
</template>
