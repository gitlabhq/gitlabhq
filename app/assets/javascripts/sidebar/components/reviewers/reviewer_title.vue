<script>
// NOTE! For the first iteration, we are simply copying the implementation of Assignees
// It will soon be overhauled in Issue https://gitlab.com/gitlab-org/gitlab/-/issues/233736
import { GlLoadingIcon } from '@gitlab/ui';
import { n__ } from '~/locale';

export default {
  name: 'ReviewerTitle',
  components: {
    GlLoadingIcon,
  },
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
    showToggle: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    reviewerTitle() {
      const reviewers = this.numberOfReviewers;
      return n__('Reviewer', `%d Reviewers`, reviewers);
    },
  },
};
</script>
<template>
  <div class="title hide-collapsed">
    {{ reviewerTitle }}
    <gl-loading-icon v-if="loading" inline class="align-bottom" />
    <a
      v-if="editable"
      class="js-sidebar-dropdown-toggle edit-link float-right"
      href="#"
      data-track-event="click_edit_button"
      data-track-label="right_sidebar"
      data-track-property="reviewer"
    >
      {{ __('Edit') }}
    </a>
    <a
      v-if="showToggle"
      :aria-label="__('Toggle sidebar')"
      class="gutter-toggle float-right js-sidebar-toggle"
      href="#"
      role="button"
    >
      <i aria-hidden="true" data-hidden="true" class="fa fa-angle-double-right"></i>
    </a>
  </div>
</template>
