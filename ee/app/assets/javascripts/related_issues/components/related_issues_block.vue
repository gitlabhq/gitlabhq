<script>
import Sortable from 'sortablejs';
import tooltip from '~/vue_shared/directives/tooltip';
import Icon from '~/vue_shared/components/icon.vue';
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
    Icon,
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
        :class="{ 'panel-empty-heading border-bottom-0': !hasBody }"
        class="card-header"
      >
        <h3 class="card-title mt-0 mb-0">
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
          <div class="d-inline-flex lh-100 align-middle">
            <div
              class="js-related-issues-header-issue-count
  related-issues-header-issue-count issue-count-badge mx-1"
            >
              <span
                class="issue-count-badge-count"
              >
                <icon
                  name="issues"
                  class="mr-1 text-secondary"
                />
                {{ badgeLabel }}
              </span>
            </div>
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
        :class="{
          'related-issues-add-related-issues-form-with-break': hasRelatedIssues
        }"
        class="js-add-related-issues-form-area card-body"
      >
        <add-issuable-form
          :is-submitting="isSubmitting"
          :input-value="inputValue"
          :pending-references="pendingReferences"
          :auto-complete-sources="autoCompleteSources"
        />
      </div>
      <div
        :class="{
          'collapsed': !shouldShowTokenBody,
          'sortable-container': canReorder
        }"
        class="related-issues-token-body card-body"
      >
        <div
          v-if="isFetching"
          class="related-issues-loading-icon">
          <gl-loading-icon
            ref="loadingIcon"
            label="Fetching related issues"
            class="prepend-top-5"
          />
        </div>
        <ul
          ref="list"
          :class="{ 'content-list' : !canReorder }"
          class="flex-list issuable-list"
        >
          <li
            v-for="issue in relatedIssues"
            :key="issue.id"
            :class="{
              'user-can-drag': canReorder,
              'sortable-row': canReorder,
              'card-slim': canReorder
            }"
            :data-key="issue.id"
            :data-epic-issue-id="issue.epic_issue_id"
            class="js-related-issues-token-list-item"
          >
            <issue-item
              :id-key="issue.id"
              :display-reference="issue.reference"
              :title="issue.title"
              :path="issue.path"
              :state="issue.state"
              :can-remove="canAdmin"
              :can-reorder="canReorder"
              event-namespace="relatedIssue"
            />
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>
