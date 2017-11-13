<script>
import loadingIcon from '~/vue_shared/components/loading_icon.vue';
import tooltip from '~/vue_shared/directives/tooltip';
import eventHub from '../event_hub';
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
    isSubmitting: {
      type: Boolean,
      required: false,
      default: false,
    },
    relatedIssues: {
      type: Array,
      required: false,
      default: () => [],
    },
    canAdmin: {
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
    title: {
      type: String,
      required: false,
      default: 'Related issues',
    },
  },

  directives: {
    tooltip,
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
    shouldShowTokenBody() {
      return this.hasRelatedIssues || this.isFetching;
    },
    hasBody() {
      return this.isFormVisible || this.shouldShowTokenBody;
    },
    badgeLabel() {
      return this.isFetching && this.relatedIssues.length === 0 ? '...' : this.relatedIssues.length;
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
};
</script>

<template>
  <div class="related-issues-block">
    <div
      class="panel-slim panel-default">
      <div
        class="panel-heading"
        :class="{ 'panel-empty-heading': !this.hasBody }">
        <h3 class="panel-title">
          {{ title }}
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
              :class="{ 'has-btn': this.canAdmin }">
              {{ badgeLabel }}
            </span>
            <button
              v-if="canAdmin"
              ref="issueCountBadgeAddButton"
              type="button"
              class="js-issue-count-badge-add-button issue-count-badge-add-button btn btn-sm btn-default"
              aria-label="Add an issue"
              data-placement="top"
              @click="toggleAddRelatedIssuesForm">
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
        class="js-add-related-issues-form-area panel-body"
        :class="{
          'related-issues-add-related-issues-form-with-break': hasRelatedIssues
        }">
        <add-issuable-form
          :is-submitting="isSubmitting"
          :input-value="inputValue"
          :pending-references="pendingReferences"
          :auto-complete-sources="autoCompleteSources" />
      </div>
      <div
        class="related-issues-token-body panel-body"
        :class="{
            'collapsed': !shouldShowTokenBody
        }">
        <div
          v-if="isFetching"
          class="related-issues-loading-icon">
          <loadingIcon
            ref="loadingIcon"
            label="Fetching related issues" />
        </div>
        <ul
          class="flex-list content-list issuable-list">
          <li
            :key="issue.id"
            v-for="issue in relatedIssues"
            class="js-related-issues-token-list-item">
            <issue-token
              event-namespace="relatedIssue"
              :id-key="issue.id"
              :display-reference="issue.reference"
              :title="issue.title"
              :path="issue.path"
              :state="issue.state"
              :can-remove="canAdmin"
            />
          </li>
        </ul>
        </div>
      </div>
    </div>
  </div>
</template>
