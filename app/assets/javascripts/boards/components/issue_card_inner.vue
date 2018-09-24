<script>
import $ from 'jquery';
import { sprintf, __ } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import IssueSummaryItems from './issue_summary_items.vue';
import UserAvatarLink from '../../vue_shared/components/user_avatar/user_avatar_link.vue';
import eventHub from '../eventhub';
import tooltip from '../../vue_shared/directives/tooltip';

const Store = gl.issueBoards.BoardsStore;

export default {
  components: {
    Icon,
    UserAvatarLink,
    IssueSummaryItems,
  },
  directives: {
    tooltip,
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
      assigneesImgSize: 24,
    };
  },
  computed: {
    numberOverLimit() {
      return this.issue.assignees.length - this.limitBeforeCounter;
    },
    assigneeCounterTooltip() {
      const count = this.assigneeCounterLabel;
      return sprintf(__('%{count} more assignees'), { count: count.replace('+', '') });
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
  updated() {
    this.toggleIssuePathTooltip();
  },
  mounted() {
    this.toggleIssuePathTooltip();
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
      return `<span class="bold">Assignee</span><br/>${assignee.name} <span class="text-white-50">@${
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
      $(e.currentTarget).tooltip('hide');

      this.applyFilter(filter);
    },
    filterByWeight(weight, e) {
      if (!this.updateFilters) return;

      const issueWeight = encodeURIComponent(weight);
      const filter = `weight=${issueWeight}`;
      $(e.currentTarget).tooltip('hide');

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
    },
    toggleIssuePathTooltip() {
      const issuePathEl = this.$el.querySelector('.board-issue-path');

      if (!issuePathEl) return;

      // If the element has an ellipsis enable tooltips
      if (issuePathEl.offsetWidth < issuePathEl.scrollWidth) {
        $(issuePathEl).tooltip('enable');
      } else {
        $(issuePathEl).tooltip('disable');
      }
    },
  },
};
</script>
<template>
  <div>
    <div class="board-card-header">
      <h4 class="board-card-title append-bottom-8 prepend-top-0">
        <icon
          v-if="issue.confidential"
          v-tooltip
          name="eye-slash"
          title="Confidential"
          class="confidential-icon append-right-4"
        /><a
          :href="issue.path"
          :title="issue.title"
          class="js-no-trigger">{{ issue.title }}</a>
      </h4>
    </div>
    <div
      v-if="showLabelFooter"
      class="board-card-labels append-bottom-4"
    >
      <button
        v-for="label in issue.labels"
        v-if="showLabel(label)"
        :key="label.id"
        v-tooltip
        :style="labelStyle(label)"
        :title="label.description"
        class="badge color-label append-right-4 append-bottom-4"
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
          class="board-card-number append-right-8 append-bottom-8"
        >
          <span
            v-if="issueReferencePath"
            v-tooltip
            :title="issueReferencePath"
            class="board-issue-path block-truncated bold"
            data-container="body"
            data-placement="bottom"
          >
            {{ issueReferencePath }}
          </span>#{{ issue.iid }}
        </span>
        <issue-summary-items
          :issue="issue"
          @filterweight="filterByWeight(issue.weight, $event)"
        />
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
          :img-size="assigneesImgSize"
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
