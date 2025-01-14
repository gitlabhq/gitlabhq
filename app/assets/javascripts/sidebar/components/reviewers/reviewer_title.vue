<script>
import { GlLoadingIcon, GlTooltipDirective } from '@gitlab/ui';
import { n__, s__ } from '~/locale';
import ReviewerDropdown from '~/merge_requests/components/reviewers/reviewer_dropdown.vue';

export default {
  name: 'ReviewerTitle',
  components: {
    GlLoadingIcon,
    ReviewerDropdown,
  },
  directives: {
    Tooltip: GlTooltipDirective,
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
    class="hide-collapsed gl-flex gl-items-center gl-gap-2 gl-font-bold gl-leading-20 gl-text-default"
  >
    {{ reviewerTitle }}
    <gl-loading-icon v-if="loading" size="sm" inline class="align-bottom" />
    <template v-if="editable">
      <reviewer-dropdown
        class="gl-ml-auto"
        :selected-reviewers="reviewers"
        :visible-reviewers="reviewers"
      />
    </template>
  </div>
</template>
