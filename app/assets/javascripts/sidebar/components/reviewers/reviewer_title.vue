<script>
import { GlLoadingIcon, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
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
  i18n: {
    changeReviewer: s__('MergeRequest|Change reviewer'),
  },
};
</script>
<template>
  <div
    class="hide-collapsed gl-flex gl-items-center gl-gap-2 gl-font-bold gl-leading-20 gl-text-default"
  >
    {{ __('Reviewer') }}
    <gl-loading-icon v-if="loading" size="sm" inline class="align-bottom" />
    <template v-if="editable">
      <reviewer-dropdown
        class="gl-ml-auto"
        usage="simple"
        :selected-reviewers="reviewers"
        :eligible-reviewers="reviewers"
      />
    </template>
  </div>
</template>
