<script>
import '~/commons/bootstrap';
import { GlTooltipDirective } from '@gitlab/ui';
import { sprintf } from '~/locale';
import IssueMilestone from '../../components/issue/issue_milestone.vue';
import IssueAssignees from '../../components/issue/issue_assignees.vue';
import relatedIssuableMixin from '../../mixins/related_issuable_mixin';
import CiIcon from '../ci_icon.vue';

export default {
  name: 'IssueItem',
  components: {
    IssueMilestone,
    IssueAssignees,
    CiIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [relatedIssuableMixin],
  props: {
    canReorder: {
      type: Boolean,
      required: false,
      default: false,
    },
    greyLinkWhenMerged: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    stateTitle() {
      return sprintf(
        '<span class="bold">%{state}</span> %{timeInWords}<br/><span class="text-tertiary">%{timestamp}</span>',
        {
          state: this.stateText,
          timeInWords: this.stateTimeInWords,
          timestamp: this.stateTimestamp,
        },
      );
    },
    issueableLinkClass() {
      return this.greyLinkWhenMerged
        ? `sortable-link ${this.state === 'merged' ? ' text-secondary' : ''}`
        : 'sortable-link';
    },
  },
};
</script>

<template>
  <div
    :class="{
      'issuable-info-container': !canReorder,
      'card-body': canReorder,
    }"
    class="item-body d-flex align-items-center p-2 p-lg-3 p-xl-2 pl-xl-3"
  >
    <div class="item-contents d-flex align-items-center flex-wrap flex-grow-1 flex-xl-nowrap">
      <div class="item-title d-flex align-items-center mb-1 mb-xl-0">
        <icon
          v-if="hasState"
          v-tooltip
          :css-classes="iconClass"
          :name="iconName"
          :size="16"
          :title="stateTitle"
          :aria-label="state"
          data-html="true"
        />
        <icon
          v-if="confidential"
          v-gl-tooltip
          name="eye-slash"
          :size="16"
          :title="__('Confidential')"
          class="confidential-icon append-right-4 align-self-baseline align-self-md-auto mt-xl-0"
          :aria-label="__('Confidential')"
        />
        <a :href="computedPath" :class="issueableLinkClass">{{ title }}</a>
      </div>
      <div class="item-meta d-flex flex-wrap mt-xl-0 justify-content-xl-end flex-xl-nowrap">
        <div
          class="d-flex align-items-center item-path-id order-md-0 mt-md-0 mt-1 ml-xl-2 mr-xl-auto"
        >
          <icon
            v-if="hasState"
            v-tooltip
            :css-classes="iconClass"
            :name="iconName"
            :size="16"
            :title="stateTitle"
            :aria-label="state"
            data-html="true"
            class="d-xl-none"
          />
          <span v-tooltip :title="itemPath" class="path-id-text d-inline-block">{{
            itemPath
          }}</span>
          {{ pathIdSeparator }}{{ itemId }}
        </div>
        <div
          class="item-meta-child d-flex align-items-center order-0 flex-wrap mr-md-1 ml-md-auto ml-xl-2 flex-xl-nowrap"
        >
          <span v-if="hasPipeline" class="mr-ci-status pr-2">
            <a :href="pipelineStatus.details_path">
              <ci-icon v-gl-tooltip :status="pipelineStatus" :title="pipelineStatusTooltip" />
            </a>
          </span>
          <issue-milestone
            v-if="hasMilestone"
            :milestone="milestone"
            class="d-flex align-items-center item-milestone"
          />
          <slot name="dueDate"></slot>
          <slot name="weight"></slot>
        </div>
        <issue-assignees
          v-if="assignees.length"
          :assignees="assignees"
          class="item-assignees d-inline-flex align-items-center align-self-end ml-auto ml-md-0 mb-md-0 order-2 flex-xl-grow-0 mt-xl-0 mr-xl-1"
        />
      </div>
    </div>
    <button
      v-if="canRemove"
      ref="removeButton"
      v-tooltip
      :disabled="removeDisabled"
      type="button"
      class="btn btn-default btn-svg btn-item-remove js-issue-item-remove-button qa-remove-issue-button mr-xl-0 align-self-xl-center"
      title="Remove"
      aria-label="Remove"
      @click="onRemoveRequest"
    >
      <icon :size="16" class="btn-item-remove-icon" name="close" />
    </button>
  </div>
</template>
