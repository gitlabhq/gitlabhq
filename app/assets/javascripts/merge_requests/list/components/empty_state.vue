<script>
import emptyStateSvg from '@gitlab/svgs/dist/illustrations/empty-state/empty-search-md.svg';
import emptyMergeRequestsStateSvg from '@gitlab/svgs/dist/illustrations/empty-state/empty-merge-requests-md.svg';
import { GlButton, GlEmptyState } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlButton,
    GlEmptyState,
  },
  inject: {
    newMergeRequestPath: {
      default: false,
    },
  },
  props: {
    hasSearch: {
      type: Boolean,
      required: false,
      default: false,
    },
    isOpenTab: {
      type: Boolean,
      required: false,
      default: true,
    },
    hasMergeRequests: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    title() {
      if (this.hasSearch) {
        return __('No results found');
      }

      if (!this.hasMergeRequests) {
        return __(
          "Merge requests are a place to propose changes you've made to a project and discuss those changes with others",
        );
      }

      if (this.isOpenTab) {
        return __('There are no open merge requests');
      }

      return __('There are no closed merge requests');
    },
    description() {
      if (this.hasSearch) {
        return __('To widen your search, change or remove filters above.');
      }

      if (!this.hasMergeRequests) {
        return __('Interested parties can even contribute by pushing commits if they want to.');
      }

      return null;
    },
    svgPath() {
      return this.hasSearch ? emptyStateSvg : emptyMergeRequestsStateSvg;
    },
  },
};
</script>

<template>
  <gl-empty-state
    :description="description"
    :title="title"
    :svg-path="svgPath"
    data-testid="issuable-empty-state"
  >
    <template #actions>
      <gl-button
        v-if="newMergeRequestPath"
        :href="newMergeRequestPath"
        variant="confirm"
        data-event-tracking="click_new_merge_request_empty_list"
        data-testid="new-merge-request-button"
      >
        {{ __('New merge request') }}
      </gl-button>
    </template>
  </gl-empty-state>
</template>
