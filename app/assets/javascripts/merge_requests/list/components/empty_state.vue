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
    searchTimeout: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    title() {
      if (this.searchTimeout) {
        return __('Too many results to display');
      }

      if (this.hasSearch) {
        return __('No results found');
      }

      if (!this.hasMergeRequests) {
        return __('Create a merge request to suggest changes to the repository.');
      }

      if (this.isOpenTab) {
        return __('There are no open merge requests');
      }

      return __('There are no closed merge requests');
    },
    description() {
      if (this.searchTimeout) {
        return __('Edit your search or add a filter.');
      }

      if (this.hasSearch) {
        return __('To widen your search, change or remove filters above.');
      }

      if (!this.hasMergeRequests) {
        return __(
          'Use merge requests to propose, collaborate, and review code changes with others.',
        );
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
    content-class="gl-max-w-75"
  >
    <template #actions>
      <gl-button
        v-if="newMergeRequestPath && !searchTimeout"
        :href="newMergeRequestPath"
        variant="confirm"
        data-event-tracking="click_new_merge_request_empty_list"
        data-testid="new-merge-request-button"
      >
        {{ __('Create merge request') }}
      </gl-button>
    </template>
  </gl-empty-state>
</template>
