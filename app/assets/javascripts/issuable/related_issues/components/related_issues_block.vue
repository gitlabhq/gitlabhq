<script>
import eventHub from '../event_hub';
import loadingIcon from '../../../vue_shared/components/loading_icon.vue';
import issueToken from './issue_token.vue';
import addIssuableForm from './add_issuable_form.vue';

export default {
  name: 'RelatedIssuesBlock',

  props: {
    isFetching: {
      type: Boolean,
      required: false,
      default: false,
    },
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
    pendingReferences: {
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
    autoCompleteSources: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },

  components: {
    loadingIcon,
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
    toggleAddRelatedIssuesForm() {
      eventHub.$emit('toggleAddRelatedIssuesForm');
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
        <h3 class="panel-title related-issues-panel-title">
          <div>
            Related issues
            <a
              v-if="hasHelpPath"
              :href="helpPath">
              <i
                class="related-issues-header-help-icon fa fa-question-circle"
                aria-label="Read more about related issues">
              </i>
            </a>
            <div class="js-related-issues-header-issue-count related-issues-header-issue-count issue-count-badge">
              <span
                class="issue-count-badge-count"
                :class="{ 'has-btn': this.canAddRelatedIssues }">
                {{ relatedIssueCount }}
              </span>
              <button
                ref="issueCountBadgeAddButton"
                v-if="canAddRelatedIssues"
                type="button"
                class="js-issue-count-badge-add-button issue-count-badge-add-button btn btn-small btn-default"
                title="Add an issue"
                aria-label="Add an issue"
                data-toggle="tooltip"
                data-placement="top"
                @click="toggleAddRelatedIssuesForm">
                <i
                  class="fa fa-plus"
                  aria-hidden="true">
                </i>
              </button>
            </div>
          </div>
          <div>
            <loadingIcon
              ref="loadingIcon"
              v-if="isFetching"
              label="Fetching related issues" />
          </div>
        </h3>
      </div>
      <div
        v-if="isFormVisible"
        class="js-add-related-issues-form-area panel-body"
        :class="{
          'related-issues-add-related-issues-form-with-break': hasRelatedIssues
        }">
        <add-issuable-form
          :input-value="inputValue"
          :pending-references="pendingReferences"
          add-button-label="Add related issues"
          :auto-complete-sources="autoCompleteSources" />
      </div>
      <div
        v-if="hasRelatedIssues"
        class="panel-body">
        <ul
          class="related-issues-token-body">
          <li
            :key="issue.id"
            v-for="issue in relatedIssues"
            class="js-related-issues-token-list-item related-issues-token-list-item">
            <issue-token
              event-namespace="relatedIssue"
              :id-key="issue.id"
              :display-reference="issue.reference"
              :title="issue.title"
              :path="issue.path"
              :state="issue.state"
              :can-remove="true" />
          </li>
        </ul>
        </div>
      </div>
    </div>
  </div>
</template>
