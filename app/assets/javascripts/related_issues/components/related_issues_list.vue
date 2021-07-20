<script>
import { GlLoadingIcon } from '@gitlab/ui';
import Sortable from 'sortablejs';
import sortableConfig from '~/sortable/sortable_config';
import RelatedIssuableItem from '~/vue_shared/components/issue/related_issuable_item.vue';

export default {
  name: 'RelatedIssuesList',
  components: {
    GlLoadingIcon,
    RelatedIssuableItem,
  },
  props: {
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
    heading: {
      type: String,
      required: false,
      default: '',
    },
    isFetching: {
      type: Boolean,
      required: false,
      default: false,
    },
    issuableType: {
      type: String,
      required: true,
    },
    pathIdSeparator: {
      type: String,
      required: true,
    },
    relatedIssues: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  mounted() {
    if (this.canReorder) {
      this.sortable = Sortable.create(this.$refs.list, {
        ...sortableConfig,
        onStart: this.addDraggingCursor,
        onEnd: this.reordered,
      });
    }
  },
  methods: {
    getBeforeAfterId(itemEl) {
      const prevItemEl = itemEl.previousElementSibling;
      const nextItemEl = itemEl.nextElementSibling;

      return {
        beforeId: prevItemEl && parseInt(prevItemEl.dataset.orderingId, 10),
        afterId: nextItemEl && parseInt(nextItemEl.dataset.orderingId, 10),
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
    issuableOrderingId({ epicIssueId, id }) {
      return this.issuableType === 'issue' ? epicIssueId : id;
    },
  },
};
</script>

<template>
  <div>
    <h4 v-if="heading" class="gl-font-base mt-0">{{ heading }}</h4>
    <div
      class="related-issues-token-body bordered-box bg-white"
      :class="{ 'sortable-container': canReorder }"
    >
      <div
        v-if="isFetching"
        class="related-issues-loading-icon"
        data-qa-selector="related_issues_loading_placeholder"
      >
        <gl-loading-icon
          ref="loadingIcon"
          size="sm"
          label="Fetching linked issues"
          class="gl-mt-2"
        />
      </div>
      <ul ref="list" :class="{ 'content-list': !canReorder }" class="related-items-list">
        <li
          v-for="issue in relatedIssues"
          :key="issue.id"
          :class="{
            'user-can-drag': canReorder,
            'sortable-row': canReorder,
            'card card-slim': canReorder,
          }"
          :data-key="issue.id"
          :data-ordering-id="issuableOrderingId(issue)"
          class="js-related-issues-token-list-item list-item pt-0 pb-0"
        >
          <related-issuable-item
            :id-key="issue.id"
            :display-reference="issue.reference"
            :confidential="issue.confidential"
            :title="issue.title"
            :path="issue.path"
            :state="issue.state"
            :milestone="issue.milestone"
            :assignees="issue.assignees"
            :created-at="issue.createdAt"
            :closed-at="issue.closedAt"
            :weight="issue.weight"
            :due-date="issue.dueDate"
            :can-remove="canAdmin"
            :can-reorder="canReorder"
            :path-id-separator="pathIdSeparator"
            :is-locked="issue.lockIssueRemoval"
            :locked-message="issue.lockedMessage"
            event-namespace="relatedIssue"
            data-qa-selector="related_issuable_content"
            @relatedIssueRemoveRequest="$emit('relatedIssueRemoveRequest', $event)"
          />
        </li>
      </ul>
    </div>
  </div>
</template>
