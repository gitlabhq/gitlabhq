<script>
import Sortable from 'sortablejs';
import loadingIcon from '~/vue_shared/components/loading_icon.vue';
import tooltip from '~/vue_shared/directives/tooltip';
import sortableConfig from 'ee/sortable/sortable_config';
import eventHub from '../event_hub';
import issueItem from './issue_item.vue';
import addIssuableForm from './add_issuable_form.vue';

export default {
  name: 'RelatedIssuesBlock',
  directives: {
    tooltip,
  },
  components: {
    loadingIcon,
    addIssuableForm,
    issueItem,
  },
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
    canReorder: {
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
  mounted() {
    if (this.canReorder) {
      this.sortable = Sortable.create(
        this.$refs.list,
        Object.assign({}, sortableConfig, {
          onStart: this.addDraggingCursor,
          onEnd: this.reordered,
        }),
      );
    }
  },
  methods: {
    toggleAddRelatedIssuesForm() {
      eventHub.$emit('toggleAddRelatedIssuesForm');
    },
    getBeforeAfterId(itemEl) {
      const prevItemEl = itemEl.previousElementSibling;
      const nextItemEl = itemEl.nextElementSibling;

      return {
        beforeId: prevItemEl && parseInt(prevItemEl.dataset.epicIssueId, 0),
        afterId: nextItemEl && parseInt(nextItemEl.dataset.epicIssueId, 0),
      };
    },
    reordered(event) {
      this.removeDraggingCursor();
      const { beforeId, afterId } = this.getBeforeAfterId(event.item);
      const { oldIndex, newIndex } = event;

      this.$emit('saveReorder', {
        issueId: parseInt(event.item.dataset.key, 10),
        oldIndex,
        newIndex,
        afterId,
        beforeId,
      });
    },
    addDraggingCursor() {
      document.body.classList.add('is-dragging');
    },
    removeDraggingCursor() {
      document.body.classList.remove('is-dragging');
    },
  },
};
</script>

<template>
  <div class="related-issues-block">
    <div
      class="card-slim"
    >
      <div
        class="card-header"
        :class="{ 'panel-empty-heading border-bottom-0': !hasBody }"
      >
        <h3 class="card-title mb-0">
          {{ title }}
          <a
            v-if="hasHelpPath"
            :href="helpPath"
          >
            <i
              class="related-issues-header-help-icon
fa fa-question-circle"
              aria-label="Read more about related issues">
            </i>
          </a>
          <div
            class="js-related-issues-header-issue-count
related-issues-header-issue-count issue-count-badge"
          >
            <span
              class="issue-count-badge-count"
              :class="{ 'has-btn': canAdmin }"
            >
              {{ badgeLabel }}
            </span>
            <button
              v-if="canAdmin"
              ref="issueCountBadgeAddButton"
              type="button"
              class="js-issue-count-badge-add-button
issue-count-badge-add-button btn btn-sm btn-default"
              aria-label="Add an issue"
              data-placement="top"
              @click="toggleAddRelatedIssuesForm"
            >
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
        class="js-add-related-issues-form-area card-body"
        :class="{
          'related-issues-add-related-issues-form-with-break': hasRelatedIssues
        }"
      >
        <add-issuable-form
          :is-submitting="isSubmitting"
          :input-value="inputValue"
          :pending-references="pendingReferences"
          :auto-complete-sources="autoCompleteSources"
        />
      </div>
      <div
        class="related-issues-token-body card-body"
        :class="{
          'collapsed': !shouldShowTokenBody,
          'sortable-container': canReorder
        }"
      >
        <div
          v-if="isFetching"
          class="related-issues-loading-icon">
          <loadingIcon
            ref="loadingIcon"
            label="Fetching related issues"
          />
        </div>
        <ul
          ref="list"
          class="flex-list issuable-list"
          :class="{ 'content-list' : !canReorder }"
        >
          <li
            :key="issue.id"
            v-for="issue in relatedIssues"
            class="js-related-issues-token-list-item"
            :class="{
              'user-can-drag': canReorder,
              'sortable-row': canReorder,
              'card-slim': canReorder
            }"
            :data-key="issue.id"
            :data-epic-issue-id="issue.epic_issue_id"
          >
            <issue-item
              event-namespace="relatedIssue"
              :id-key="issue.id"
              :display-reference="issue.reference"
              :title="issue.title"
              :path="issue.path"
              :state="issue.state"
              :can-remove="canAdmin"
              :can-reorder="canReorder"
            />
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>
