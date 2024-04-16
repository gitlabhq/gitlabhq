<script>
// NOTE! For the first iteration, we are simply copying the implementation of Assignees
// It will soon be overhauled in Issue https://gitlab.com/gitlab-org/gitlab/-/issues/233736
import { MountingPortal } from 'portal-vue';
import { GlLoadingIcon, GlButton, GlTooltipDirective } from '@gitlab/ui';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { n__ } from '~/locale';
import ReviewerDrawer from '~/merge_requests/components/reviewers/reviewer_drawer.vue';

export default {
  name: 'ReviewerTitle',
  components: {
    MountingPortal,
    GlLoadingIcon,
    GlButton,
    ReviewerDrawer,
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
  },
  data() {
    return {
      drawerOpen: false,
    };
  },
  computed: {
    reviewerTitle() {
      const reviewers = this.numberOfReviewers;
      return n__('Reviewer', `%d Reviewers`, reviewers);
    },
  },
  methods: {
    toggleDrawerOpen(drawerOpen = !this.drawerOpen) {
      this.drawerOpen = drawerOpen;
    },
  },
};
</script>
<template>
  <div
    class="hide-collapsed gl-display-flex gl-align-items-center gl-line-height-20 gl-text-gray-900 gl-font-weight-bold gl-gap-2"
  >
    {{ reviewerTitle }}
    <gl-loading-icon v-if="loading" size="sm" inline class="align-bottom" />
    <template v-if="editable">
      <gl-button
        v-tooltip.hover
        :title="__('Quick assign')"
        class="js-sidebar-dropdown-toggle edit-link gl-ml-auto hide-collapsed gl-float-right"
        data-track-action="click_edit_button"
        data-track-label="right_sidebar"
        data-track-property="reviewer"
        data-testid="reviewers-edit-button"
        category="tertiary"
        size="small"
        :icon="glFeatures.reviewerAssignDrawer ? 'plus' : ''"
        ><template v-if="!glFeatures.reviewerAssignDrawer">{{ __('Edit') }}</template></gl-button
      >
      <gl-button
        v-if="glFeatures.reviewerAssignDrawer"
        v-tooltip.hover
        :title="__('Add or edit reviewers')"
        category="tertiary"
        size="small"
        class="gl-float-right gl-ml-2"
        data-testid="drawer-toggle"
        @click="toggleDrawerOpen(!drawerOpen)"
      >
        {{ __('Edit') }}
      </gl-button>
    </template>
    <mounting-portal v-if="glFeatures.reviewerAssignDrawer" mount-to="#js-reviewer-drawer-portal">
      <reviewer-drawer :open="drawerOpen" @close="toggleDrawerOpen(false)" />
    </mounting-portal>
  </div>
</template>
