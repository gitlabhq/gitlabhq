<script>
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
  },
};
</script>

<template>
  <div
    :class="{
      'issuable-info-container': !canReorder,
      'card-body': canReorder,
    }"
    class="item-body"
  >
    <div class="item-contents">
      <div class="item-title d-flex align-items-center">
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
          class="confidential-icon append-right-4"
          :aria-label="__('Confidential')"
        />
        <a :href="computedPath" class="sortable-link">{{ title }}</a>
      </div>
      <div class="item-meta">
        <div class="d-flex align-items-center item-path-id">
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
        <div class="item-meta-child d-flex align-items-center">
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
          class="item-assignees d-inline-flex"
        />
      </div>
    </div>
    <button
      v-if="canRemove"
      ref="removeButton"
      v-tooltip
      :disabled="removeDisabled"
      type="button"
      class="btn btn-default btn-svg btn-item-remove js-issue-item-remove-button qa-remove-issue-button"
      title="Remove"
      aria-label="Remove"
      @click="onRemoveRequest"
    >
      <icon :size="16" class="btn-item-remove-icon" name="close" />
    </button>
  </div>
</template>
