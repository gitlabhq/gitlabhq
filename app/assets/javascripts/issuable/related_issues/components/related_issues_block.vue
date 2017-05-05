<script>
import eventHub from '../event_hub';
import issueToken from './issue_token.vue';
import addIssuableForm from './add_issuable_form.vue';

export default {
  name: 'RelatedIssuesBlock',

  props: {
    relatedIssues: {
      type: Array,
      required: false,
      default: () => [],
    },
    canAddRelatedIssues: {
      type: Boolean,
      required: false,
      default: false,
    },
    isFormVisible: {
      type: Boolean,
      required: false,
      default: false,
    },
    pendingRelatedIssues: {
      type: Array,
      required: false,
      default: () => [],
    },
    inputValue: {
      type: String,
      required: false,
      default: '',
    },
    helpPath: {
      type: String,
      required: false,
      default: '',
    },
  },

  components: {
    addIssuableForm,
    issueToken,
  },

  computed: {
    hasRelatedIssues() {
      return this.relatedIssues.length > 0;
    },
    relatedIssueCount() {
      return this.relatedIssues.length;
    },
    hasHelpPath() {
      return this.helpPath.length > 0;
    },
  },

  methods: {
    showAddRelatedIssuesForm() {
      eventHub.$emit('showAddRelatedIssuesForm');
    },
  },

  updated() {
    const addIssueButton = this.$refs.issueCountBadgeAddButton;
    if (addIssueButton) {
      $(addIssueButton).tooltip('fixTitle');
    }
  },
};
</script>

<template>
  <div class="related-issues-block">
    <div
      class="panel-slim panel-default">
      <div
        class="panel-heading"
        :class="{ 'panel-empty-heading': !this.hasRelatedIssues }">
        <h3 class="panel-title">
          Related issues
          <a
            v-if="hasHelpPath"
            :href="helpPath">
            <i
              class="related-issues-header-help-icon fa fa-question-circle"
              aria-label="Read more about related issues">
            </i>
          </a>
          <div class="related-issues-header-issue-count issue-count-badge">
            <span
              class="issue-count-badge-count"
              :class="{ 'has-btn': this.canAddRelatedIssues }">
              {{ relatedIssueCount }}
            </span>
            <button
              ref="issueCountBadgeAddButton"
              v-if="canAddRelatedIssues"
              type="button"
              class="issue-count-badge-add-button btn btn-small btn-default"
              title="Add an issue"
              aria-label="Add an issue"
              data-toggle="tooltip"
              data-placement="top"
              @click="showAddRelatedIssuesForm">
              <i
                class="fa fa-plus"
                aria-hidden="true">
              </i>
            </button>
          </div>
        </h3>
      </div>
      <div
        v-if="isFormVisible"
        class="js-add-related-issues-form-area related-issues-add-related-issues-form panel-body">
        <add-issuable-form
          :input-value="inputValue"
          :pending-issuables="pendingRelatedIssues"
          add-button-label="Add related issues" />
      </div>
      <div
        v-if="hasRelatedIssues"
        class="panel-body">
        <ul
          class="related-issues-token-body">
          <li
            :key="issue.reference"
            v-for="issue in relatedIssues"
            class="js-related-issues-token-list-item related-issues-token-list-item">
            <issue-token
              event-namespace="relatedIssue"
              :reference="issue.reference"
              :display-reference="issue.displayReference"
              :title="issue.title"
              :path="issue.path"
              :state="issue.state"
              :fetch-status="issue.fetchStatus"
              :can-remove="issue.canRemove" />
          </li>
        </ul>
        </div>
      </div>
    </div>
  </div>
</template>
