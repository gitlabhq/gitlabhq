<script>
import { GlLoadingIcon } from '@gitlab/ui';
import Sortable from 'sortablejs';
import RelatedIssuableItem from '~/issuable/components/related_issuable_item.vue';
import { TYPE_ISSUE } from '~/issues/constants';
import { defaultSortableOptions } from '~/sortable/constants';

export default {
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
    listLinkType: {
      type: String,
      required: false,
      default: '',
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
        ...defaultSortableOptions,
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
      return this.issuableType === TYPE_ISSUE ? epicIssueId : id;
    },
  },
};
</script>

<template>
  <div :data-link-type="listLinkType">
    <h4 v-if="heading" class="gl-mx-5 -gl-mb-2 gl-mt-4 gl-text-sm gl-font-semibold gl-text-subtle">
      {{ heading }}
    </h4>
    <div class="related-issues-token-body" :class="{ 'sortable-container': canReorder }">
      <div v-if="isFetching" class="gl-mb-2" data-testid="related-issues-loading-placeholder">
        <gl-loading-icon
          ref="loadingIcon"
          size="sm"
          label="Fetching linked issues"
          class="gl-mt-2"
        />
      </div>
      <ul ref="list" :class="{ 'content-list': !canReorder }" class="related-items-list !gl-m-3">
        <li
          v-for="issue in relatedIssues"
          :key="issue.id"
          :class="{
            'gl-cursor-grab': canReorder,
            'sortable-row': canReorder,
            'card card-slim': canReorder,
          }"
          :data-key="issue.id"
          :data-ordering-id="issuableOrderingId(issue)"
          class="js-related-issues-token-list-item list-item !gl-border-b-0 !gl-p-0"
        >
          <related-issuable-item
            :id-key="issue.id"
            :iid="issue.iid"
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
            :work-item-type="issue.type"
            event-namespace="relatedIssue"
            data-testid="related-issuable-content"
            @relatedIssueRemoveRequest="$emit('relatedIssueRemoveRequest', $event)"
          />
        </li>
      </ul>
    </div>
  </div>
</template>
