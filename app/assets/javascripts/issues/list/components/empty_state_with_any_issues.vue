<script>
import epicEmptyStateSvg from '@gitlab/svgs/dist/illustrations/empty-state/empty-epic-md.svg';
import issuesEmptyStateSvg from '@gitlab/svgs/dist/illustrations/empty-state/empty-issues-md.svg';
import { GlButton, GlEmptyState } from '@gitlab/ui';
import { __, s__ } from '~/locale';

export default {
  components: {
    GlButton,
    GlEmptyState,
  },
  inject: {
    newIssuePath: {
      default: false,
    },
    showNewIssueLink: {
      default: false,
    },
  },
  props: {
    hasSearch: {
      type: Boolean,
      required: false,
      default: false,
    },
    isEpic: {
      type: Boolean,
      required: false,
      default: false,
    },
    isOpenTab: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    closedTabTitle() {
      return this.isEpic ? __('There are no closed epics') : s__('Issues|No closed issues');
    },
    openTabTitle() {
      return this.isEpic ? __('There are no open epics') : s__('Issues|No open issues');
    },
    noIssueDescription() {
      return this.isEpic
        ? ''
        : s__(
            'Issues|Use issues (also known as tickets or stories on other platforms) to collaborate on ideas, solve problems, and plan your project.',
          );
    },
    svgPath() {
      return this.isEpic ? epicEmptyStateSvg : issuesEmptyStateSvg;
    },
  },
};
</script>

<template>
  <gl-empty-state
    v-if="hasSearch"
    :description="__('To widen your search, change or remove filters above')"
    :title="__('Sorry, your filter produced no results')"
    :svg-path="svgPath"
    data-testid="issuable-empty-state"
  >
    <template #actions>
      <slot name="new-issue-button">
        <gl-button v-if="showNewIssueLink" :href="newIssuePath" variant="confirm">
          {{ __('Create issue') }}
        </gl-button>
      </slot>
    </template>
  </gl-empty-state>

  <gl-empty-state
    v-else-if="isOpenTab"
    :title="openTabTitle"
    :description="noIssueDescription"
    :svg-path="svgPath"
    data-testid="issuable-empty-state"
  >
    <template #actions>
      <slot name="new-issue-button">
        <gl-button v-if="showNewIssueLink" :href="newIssuePath" variant="confirm">
          {{ __('Create issue') }}
        </gl-button>
      </slot>
    </template>
  </gl-empty-state>

  <gl-empty-state
    v-else
    :title="closedTabTitle"
    :svg-path="svgPath"
    data-testid="issuable-empty-state"
  />
</template>
