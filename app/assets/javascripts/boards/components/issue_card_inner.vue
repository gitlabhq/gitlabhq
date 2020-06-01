<script>
import { sortBy } from 'lodash';
import { mapState } from 'vuex';
import { GlLabel, GlTooltipDirective } from '@gitlab/ui';
import issueCardInner from 'ee_else_ce/boards/mixins/issue_card_inner';
import { sprintf, __ } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate.vue';
import UserAvatarLink from '../../vue_shared/components/user_avatar/user_avatar_link.vue';
import IssueDueDate from './issue_due_date.vue';
import IssueTimeEstimate from './issue_time_estimate.vue';
import boardsStore from '../stores/boards_store';
import { isScopedLabel } from '~/lib/utils/common_utils';

export default {
  components: {
    GlLabel,
    Icon,
    UserAvatarLink,
    TooltipOnTruncate,
    IssueDueDate,
    IssueTimeEstimate,
    IssueCardWeight: () => import('ee_component/boards/components/issue_card_weight.vue'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [issueCardInner],
  props: {
    issue: {
      type: Object,
      required: true,
    },
    issueLinkBase: {
      type: String,
      required: true,
    },
    list: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    rootPath: {
      type: String,
      required: true,
    },
    updateFilters: {
      type: Boolean,
      required: false,
      default: false,
    },
    groupId: {
      type: Number,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      limitBeforeCounter: 2,
      maxRender: 3,
      maxCounter: 99,
    };
  },
  computed: {
    ...mapState(['isShowingLabels']),
    numberOverLimit() {
      return this.issue.assignees.length - this.limitBeforeCounter;
    },
    assigneeCounterTooltip() {
      const { numberOverLimit, maxCounter } = this;
      const count = numberOverLimit > maxCounter ? maxCounter : numberOverLimit;
      return sprintf(__('%{count} more assignees'), { count });
    },
    assigneeCounterLabel() {
      if (this.numberOverLimit > this.maxCounter) {
        return `${this.maxCounter}+`;
      }

      return `+${this.numberOverLimit}`;
    },
    shouldRenderCounter() {
      if (this.issue.assignees.length <= this.maxRender) {
        return false;
      }

      return this.issue.assignees.length > this.numberOverLimit;
    },
    issueId() {
      if (this.issue.iid) {
        return `#${this.issue.iid}`;
      }
      return false;
    },
    showLabelFooter() {
      return this.isShowingLabels && this.issue.labels.find(this.showLabel);
    },
    issueReferencePath() {
      const { referencePath, groupId } = this.issue;
      return !groupId ? referencePath.split('#')[0] : null;
    },
    orderedLabels() {
      return sortBy(this.issue.labels.filter(this.isNonListLabel), 'title');
    },
  },
  methods: {
    isIndexLessThanlimit(index) {
      return index < this.limitBeforeCounter;
    },
    shouldRenderAssignee(index) {
      // Eg. maxRender is 4,
      // Render up to all 4 assignees if there are only 4 assigness
      // Otherwise render up to the limitBeforeCounter
      if (this.issue.assignees.length <= this.maxRender) {
        return index < this.maxRender;
      }

      return index < this.limitBeforeCounter;
    },
    assigneeUrl(assignee) {
      if (!assignee) return '';
      return `${this.rootPath}${assignee.username}`;
    },
    avatarUrlTitle(assignee) {
      return sprintf(__(`Avatar for %{assigneeName}`), { assigneeName: assignee.name });
    },
    showLabel(label) {
      if (!label.id) return false;
      return true;
    },
    isNonListLabel(label) {
      return label.id && !(this.list.type === 'label' && this.list.title === label.title);
    },
    filterByLabel(label) {
      if (!this.updateFilters) return;
      const labelTitle = encodeURIComponent(label.title);
      const filter = `label_name[]=${labelTitle}`;

      boardsStore.toggleFilter(filter);
    },
    showScopedLabel(label) {
      return boardsStore.scopedLabels.enabled && isScopedLabel(label);
    },
  },
};
</script>
<template>
  <div>
    <div class="d-flex board-card-header" dir="auto">
      <h4 class="board-card-title gl-mb-0 gl-mt-0">
        <icon
          v-if="issue.blocked"
          v-gl-tooltip
          name="issue-block"
          :title="__('Blocked issue')"
          class="issue-blocked-icon append-right-4"
          :aria-label="__('Blocked issue')"
        />
        <icon
          v-if="issue.confidential"
          v-gl-tooltip
          name="eye-slash"
          :title="__('Confidential')"
          class="confidential-icon append-right-4"
          :aria-label="__('Confidential')"
        />
        <a :href="issue.path" :title="issue.title" class="js-no-trigger" @mousemove.stop>{{
          issue.title
        }}</a>
      </h4>
    </div>
    <div v-if="showLabelFooter" class="board-card-labels prepend-top-4 d-flex flex-wrap">
      <template v-for="label in orderedLabels">
        <gl-label
          :key="label.id"
          :background-color="label.color"
          :title="label.title"
          :description="label.description"
          size="sm"
          :scoped="showScopedLabel(label)"
          @click="filterByLabel(label)"
        />
      </template>
    </div>
    <div class="board-card-footer d-flex justify-content-between align-items-end">
      <div
        class="d-flex align-items-start flex-wrap-reverse board-card-number-container overflow-hidden js-board-card-number-container"
      >
        <span
          v-if="issue.referencePath"
          class="board-card-number overflow-hidden d-flex gl-mr-3 gl-mt-3"
        >
          <tooltip-on-truncate
            v-if="issueReferencePath"
            :title="issueReferencePath"
            placement="bottom"
            class="board-issue-path block-truncated bold"
            >{{ issueReferencePath }}</tooltip-on-truncate
          >
          #{{ issue.iid }}
        </span>
        <span class="board-info-items gl-mt-3 d-inline-block">
          <issue-due-date v-if="issue.dueDate" :date="issue.dueDate" :closed="issue.closed" />
          <issue-time-estimate v-if="issue.timeEstimate" :estimate="issue.timeEstimate" />
          <issue-card-weight
            v-if="validIssueWeight"
            :weight="issue.weight"
            @click="filterByWeight(issue.weight)"
          />
        </span>
      </div>
      <div class="board-card-assignee d-flex">
        <user-avatar-link
          v-for="(assignee, index) in issue.assignees"
          v-if="shouldRenderAssignee(index)"
          :key="assignee.id"
          :link-href="assigneeUrl(assignee)"
          :img-alt="avatarUrlTitle(assignee)"
          :img-src="assignee.avatar || assignee.avatar_url"
          :img-size="24"
          class="js-no-trigger"
          tooltip-placement="bottom"
        >
          <span class="js-assignee-tooltip">
            <span class="bold d-block">{{ __('Assignee') }}</span>
            {{ assignee.name }}
            <span class="text-white-50">@{{ assignee.username }}</span>
          </span>
        </user-avatar-link>
        <span
          v-if="shouldRenderCounter"
          v-gl-tooltip
          :title="assigneeCounterTooltip"
          class="avatar-counter"
          data-placement="bottom"
          >{{ assigneeCounterLabel }}</span
        >
      </div>
    </div>
  </div>
</template>
