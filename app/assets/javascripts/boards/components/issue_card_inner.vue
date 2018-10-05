<script>
import $ from 'jquery';
import _ from 'underscore';
import { sprintf, __ } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate.vue';
import UserAvatarLink from '../../vue_shared/components/user_avatar/user_avatar_link.vue';
import eventHub from '../eventhub';
import tooltip from '../../vue_shared/directives/tooltip';
import IssueDueDate from './issue_due_date.vue';
import IssueTimeEstimate from './issue_time_estimate.vue';


const Store = gl.issueBoards.BoardsStore;

export default {
  components: {
    Icon,
    UserAvatarLink,
    TooltipOnTruncate,
    IssueDueDate,
    IssueTimeEstimate,
  },
  directives: {
    tooltip
  },
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
      assigneeImgSize: 24,
      confidentialTooltipLabel: __('Confidential'),
    };
  },
  computed: {
    numberOverLimit() {
      return this.issue.assignees.length - this.limitBeforeCounter;
    },
    assigneeCounterTooltip() {
      const { numberOverLimit,  maxCounter} = this;
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
      return this.issue.labels.find(l => this.showLabel(l)) !== undefined;
    },
    issueReferencePath() {
      const { referencePath, project } = this.issue;
      return project && referencePath.includes(project.path) ? referencePath.split('#')[0] : null;
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
    assigneeUrlTitle(assignee) {
      return `<span class="bold">Assignee</span><br/>${_.escape(assignee.name)} <span class="text-white-50">@${
        assignee.username
      }</span>`;
    },
    avatarUrlTitle(assignee) {
      return `Avatar for ${assignee.name}`;
    },
    showLabel(label) {
      if (!label.id) return false;
      return true;
    },
    filterByLabel(label, e) {
      if (!this.updateFilters) return;
      const labelTitle = encodeURIComponent(label.title);
      const filter = `label_name[]=${labelTitle}`;

      this.applyFilter(filter);
    },
    filterByWeight(weight, e) {
      if (!this.updateFilters) return;

      const issueWeight = encodeURIComponent(weight);
      const filter = `weight=${issueWeight}`;

      this.applyFilter(filter);
    },
    applyFilter(filter) {
      const filterPath = gl.issueBoards.BoardsStore.filter.path.split('&');
      const filterIndex = filterPath.indexOf(filter);

      if (filterIndex === -1) {
        filterPath.push(filter);
      } else {
        filterPath.splice(filterIndex, 1);
      }

      gl.issueBoards.BoardsStore.filter.path = filterPath.join('&');

      Store.updateFiltersUrl();

      eventHub.$emit('updateTokens');
    },
    labelStyle(label) {
      return {
        backgroundColor: label.color,
        color: label.textColor,
      };
    }
  },
};
</script>
<template>
  <div>
    <div class="board-card-header">
      <h4 class="board-card-title append-bottom-0 prepend-top-0">
        <icon
          v-if="issue.confidential"
          v-tooltip
          name="eye-slash"
          :title="confidentialTooltipLabel"
          class="confidential-icon append-right-4"
        /><a
          :href="issue.path"
          :title="issue.title"
          class="js-no-trigger"
          @mousemove.stop>{{ issue.title }}</a>
      </h4>
    </div>
    <div
      v-if="showLabelFooter"
      class="board-card-labels prepend-top-4"
    >
      <button
        v-for="label in issue.labels"
        v-if="showLabel(label)"
        :key="label.id"
        v-tooltip
        :style="labelStyle(label)"
        :title="label.description"
        class="badge color-label append-right-4 prepend-top-4"
        type="button"
        data-container="body"
        @click="filterByLabel(label, $event)"
      >
        {{ label.title }}
      </button>
    </div>
    <div class="board-card-footer d-flex justify-content-between align-items-end">
      <div class="d-flex align-items-start board-card-number-container">
        <span
          v-if="issue.referencePath"
          class="board-card-number append-right-8 prepend-top-8"
        >
          <tooltip-on-truncate
            v-if="issueReferencePath"
            :title="issueReferencePath"
            placement="bottom"
            class="board-issue-path block-truncated bold"
          >{{ issueReferencePath }}</tooltip-on-truncate>#{{ issue.iid }}
        </span>
        <span class="board-info-items prepend-top-8">
          <issue-due-date
            v-if="issue.dueDate"
            :date="issue.dueDate"
          />
          <issue-time-estimate
            v-if="issue.timeEstimate"
            :estimate="issue.timeEstimate" 
          />
        </span>
      </div>
      <div class="board-card-assignee">
        <user-avatar-link
          v-for="(assignee, index) in issue.assignees"
          v-if="shouldRenderAssignee(index)"
          :key="assignee.id"
          :link-href="assigneeUrl(assignee)"
          :img-alt="avatarUrlTitle(assignee)"
          :img-src="assignee.avatar"
          :tooltip-text="assigneeUrlTitle(assignee)"
          :img-size="assigneeImgSize"
          class="js-no-trigger"
          tooltip-placement="bottom"
        />
        <span
          v-if="shouldRenderCounter"
          v-tooltip
          :title="assigneeCounterTooltip"
          class="avatar-counter"
          data-placement="bottom"
        >
          {{ assigneeCounterLabel }}
        </span>
      </div>
    </div>
  </div>
</template>
