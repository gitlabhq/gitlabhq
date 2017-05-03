import Vue from 'vue';
import eventHub from '../eventhub';

const Store = gl.issueBoards.BoardsStore;

window.gl = window.gl || {};
window.gl.issueBoards = window.gl.issueBoards || {};

<<<<<<< HEAD
  gl.issueBoards.IssueCardInner = Vue.extend({
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
    },
    data() {
      return {
        limitBeforeCounter: 3,
        maxRender: 4,
        maxCounter: 99,
      };
    },
    computed: {
      numberOverLimit() {
        return this.issue.assignees.length - this.limitBeforeCounter;
      },
      assigneeCounterTooltip() {
        return `${this.assigneeCounterLabel} more`;
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
      cardUrl() {
        return `${this.issueLinkBase}/${this.issue.id}`;
      },
      issueId() {
        return `#${this.issue.id}`;
      },
      showLabelFooter() {
        return this.issue.labels.find(l => this.showLabel(l)) !== undefined;
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
        return `${this.rootPath}${assignee.username}`;
      },
      assigneeUrlTitle(assignee) {
        return `Assigned to ${assignee.name}`;
      },
      avatarUrlTitle(assignee) {
        return `Avatar for ${assignee.name}`;
      },
      showLabel(label) {
        if (!this.list) return true;
=======
gl.issueBoards.IssueCardInner = Vue.extend({
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
  },
  computed: {
    cardUrl() {
      return `${this.issueLinkBase}/${this.issue.id}`;
    },
    assigneeUrl() {
      return `${this.rootPath}${this.issue.assignee.username}`;
    },
    assigneeUrlTitle() {
      return `Assigned to ${this.issue.assignee.name}`;
    },
    avatarUrlTitle() {
      return `Avatar for ${this.issue.assignee.name}`;
    },
    issueId() {
      return `#${this.issue.id}`;
    },
    showLabelFooter() {
      return this.issue.labels.find(l => this.showLabel(l)) !== undefined;
    },
  },
  methods: {
    showLabel(label) {
      if (!this.list) return true;
>>>>>>> ebe5fef5b52c6561be470e7f0b2a173d81bc64c0

      return !this.list.label || label.id !== this.list.label.id;
    },
    filterByLabel(label, e) {
      if (!this.updateFilters) return;

      const filterPath = gl.issueBoards.BoardsStore.filter.path.split('&');
      const labelTitle = encodeURIComponent(label.title);
      const param = `label_name[]=${labelTitle}`;
      const labelIndex = filterPath.indexOf(param);
      $(e.currentTarget).tooltip('hide');

      if (labelIndex === -1) {
        filterPath.push(param);
      } else {
        filterPath.splice(labelIndex, 1);
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
<<<<<<< HEAD
    template: `
      <div>
        <div class="card-header">
          <h4 class="card-title">
            <i
              class="fa fa-eye-slash confidential-icon"
              v-if="issue.confidential"
              aria-hidden="true"
            />
            <a
              class="js-no-trigger"
              :href="cardUrl"
              :title="issue.title">{{ issue.title }}</a>
            <span
              class="card-number"
              v-if="issue.id"
            >
              {{ issueId }}
            </span>
          </h4>
          <div class="card-assignee">
            <a
              class="has-tooltip js-no-trigger"
              :href="assigneeUrl(assignee)"
              :title="assigneeUrlTitle(assignee)"
              v-for="(assignee, index) in issue.assignees"
              v-if="shouldRenderAssignee(index)"
              data-container="body"
              data-placement="bottom"
            >
              <img
                class="avatar avatar-inline s20"
                :src="assignee.avatarUrl"
                width="20"
                height="20"
                :alt="avatarUrlTitle(assignee)"
              />
            </a>
            <span
              class="avatar-counter has-tooltip"
              :title="assigneeCounterTooltip"
              v-if="shouldRenderCounter"
            >
             {{ assigneeCounterLabel }}
            </span>
          </div>
        </div>
        <div
          class="card-footer"
          v-if="showLabelFooter"
        >
          <button
            class="label color-label has-tooltip"
            v-for="label in issue.labels"
            type="button"
            v-if="showLabel(label)"
            @click="filterByLabel(label, $event)"
            :style="labelStyle(label)"
            :title="label.description"
            data-container="body">
            {{ label.title }}
          </button>
        </div>
=======
  },
  template: `
    <div>
      <div class="card-header">
        <h4 class="card-title">
          <i
            class="fa fa-eye-slash confidential-icon"
            v-if="issue.confidential"
            aria-hidden="true"
          />
          <a
            class="js-no-trigger"
            :href="cardUrl"
            :title="issue.title">{{ issue.title }}</a>
          <span
            class="card-number"
            v-if="issue.id"
          >
            {{ issueId }}
          </span>
        </h4>
        <a
          class="card-assignee has-tooltip js-no-trigger"
          :href="assigneeUrl"
          :title="assigneeUrlTitle"
          v-if="issue.assignee"
          data-container="body"
        >
          <img
            class="avatar avatar-inline s20 js-no-trigger"
            :src="issue.assignee.avatar"
            width="20"
            height="20"
            :alt="avatarUrlTitle"
          />
        </a>
      </div>
      <div class="card-footer" v-if="showLabelFooter">
        <button
          class="label color-label has-tooltip js-no-trigger"
          v-for="label in issue.labels"
          type="button"
          v-if="showLabel(label)"
          @click="filterByLabel(label, $event)"
          :style="labelStyle(label)"
          :title="label.description"
          data-container="body">
          {{ label.title }}
        </button>
>>>>>>> ebe5fef5b52c6561be470e7f0b2a173d81bc64c0
      </div>
    </div>
  `,
});
