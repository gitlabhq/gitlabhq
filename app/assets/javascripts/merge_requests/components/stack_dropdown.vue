<script>
import { mapState } from 'pinia';
import { GlDisclosureDropdown, GlButton, GlIcon, GlSprintf, GlTooltipDirective } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_MERGE_REQUEST } from '~/graphql_shared/constants';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { useNotes } from '~/notes/store/legacy_notes';
import mergeRequestStackQuery from '../queries/merge_request_stack.query.graphql';

export default {
  name: 'StackDropdown',
  apollo: {
    stack: {
      query: mergeRequestStackQuery,
      update: (d) => d.mergeRequest?.stack,
      variables() {
        return {
          id: this.mergeRequestId,
        };
      },
    },
  },
  components: {
    GlDisclosureDropdown,
    GlButton,
    GlIcon,
    GlSprintf,
    TimeagoTooltip,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['defaultBranch'],
  data() {
    return {
      stack: null,
    };
  },
  computed: {
    ...mapState(useNotes, ['getNoteableData']),
    dropdownItems() {
      return this.stack.toReversed();
    },
    mergeRequestId() {
      return convertToGraphQLId(TYPENAME_MERGE_REQUEST, this.getNoteableData.id);
    },
    currentMergeRequestIndex() {
      return this.stack.findIndex((mr) => mr.id === this.mergeRequestId) + 1;
    },
    toggleText() {
      return sprintf(s__('MergeRequest|%{currentIndex} of %{stackSize}'), {
        currentIndex: this.currentMergeRequestIndex,
        stackSize: this.stack.length,
      });
    },
    toggleLabel() {
      return sprintf(s__('MergeRequest|Merge request %{currentIndex} of %{stackSize} in stack'), {
        currentIndex: this.currentMergeRequestIndex,
        stackSize: this.stack.length,
      });
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    v-if="stack && stack.length"
    :items="dropdownItems"
    class="gl-ml-2"
    fluid-width
  >
    <template #header>
      <div
        class="gl-border-b-1 gl-border-b-dropdown-divider gl-p-3 gl-text-sm gl-font-bold gl-text-strong gl-border-b-solid"
      >
        {{ __('Stacked merge requests') }}
      </div>
    </template>
    <template #toggle="{ accessibilityAttributes }">
      <gl-button
        v-gl-tooltip
        v-bind="accessibilityAttributes"
        size="small"
        :aria-label="toggleLabel"
        :title="__('Stacked merge requests')"
        class="merge-request-stack-toggle"
      >
        <gl-icon name="container-image" />
        <span>{{ toggleText }}</span>
        <gl-icon name="chevron-down" />
      </gl-button>
    </template>
    <template #list-item="{ item }">
      <div class="gl-flex gl-gap-3">
        <gl-icon
          name="arrow-right"
          class="gl-flex-shrink-0"
          :class="{ 'gl-invisible': item.id !== mergeRequestId }"
        />
        <div class="gl-flex gl-flex-col gl-gap-2">
          {{ item.text }}
          <span class="gl-text-sm gl-text-subtle">
            <gl-sprintf :message="__('Open %{date}')">
              <template #date>
                <timeago-tooltip :time="item.createdAt" />
              </template>
            </gl-sprintf>
          </span>
        </div>
        <div class="gl-ml-auto">
          <div class="gl-inline-flex gl-gap-2">
            <div class="gl-whitespace-nowrap">
              <gl-icon name="doc-new" :size="12" />
              <span>{{ item.diffStatsSummary.fileCount }}</span>
            </div>
            <div class="gl-flex gl-items-center gl-text-success">
              <span>+</span>
              <span>{{ item.diffStatsSummary.additions }}</span>
            </div>
            <div class="gl-flex gl-items-center gl-text-danger">
              <span>−</span>
              <span>{{ item.diffStatsSummary.deletions }}</span>
            </div>
          </div>
        </div>
      </div>
    </template>
    <template #footer>
      <div class="gl-border-t-1 gl-border-t-dropdown-divider gl-p-3 gl-text-sm gl-border-t-solid">
        <gl-sprintf :message="s__('MergeRequest|Bottom of stack merges into %{branch} first.')">
          <template #branch>
            <span
              class="ref-container gl-relative gl-top-1 gl-inline-flex gl-max-w-26 gl-gap-2 gl-truncate gl-rounded-base gl-px-2 gl-font-monospace gl-text-sm"
              ><gl-icon name="branch" :size="12" class="gl-self-center" />{{ defaultBranch }}</span
            >
          </template>
        </gl-sprintf>
      </div>
    </template>
  </gl-disclosure-dropdown>
</template>
