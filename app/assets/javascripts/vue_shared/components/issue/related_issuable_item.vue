<script>
import { GlTooltipDirective } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import IssueMilestone from '~/vue_shared/components/issue/issue_milestone.vue';
import IssueAssignees from '~/vue_shared/components/issue/issue_assignees.vue';
import relatedIssuableMixin from '~/vue_shared/mixins/related_issuable_mixin';

export default {
  name: 'IssueItem',
  components: {
    IssueMilestone,
    IssueAssignees,
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
          state: this.isOpen ? __('Opened') : __('Closed'),
          timeInWords: this.isOpen ? this.createdAtInWords : this.closedAtInWords,
          timestamp: this.isOpen ? this.createdAtTimestamp : this.closedAtTimestamp,
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
          />
          <span v-tooltip :title="itemPath" class="path-id-text">{{ itemPath }}</span>
          {{ pathIdSeparator }}{{ itemId }}
        </div>
        <div class="item-meta-child d-flex align-items-center">
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
