<script>
import {
  GlBadge,
  GlLink,
  GlIcon,
  GlLabel,
  GlFormCheckbox,
  GlSprintf,
  GlTooltipDirective,
  GlSkeletonLoader,
} from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { STATUS_OPEN, STATUS_CLOSED } from '~/issues/constants';
import { isScopedLabel } from '~/lib/utils/common_utils';
import { isExternal, visitUrl } from '~/lib/utils/url_utility';
import { __, n__, sprintf } from '~/locale';
import IssuableAssignees from '~/issuable/components/issue_assignees.vue';

import timeagoMixin from '~/vue_shared/mixins/timeago';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import WorkItemTypeIcon from '~/work_items/components/work_item_type_icon.vue';
import WorkItemPrefetch from '~/work_items/components/work_item_prefetch.vue';
import {
  STATE_OPEN,
  STATE_CLOSED,
  WORK_ITEM_TYPE_NAME_INCIDENT,
  WORK_ITEM_TYPE_NAME_ISSUE,
  WORK_ITEM_TYPE_ENUM_INCIDENT,
  WORK_ITEM_TYPE_ENUM_ISSUE,
  WORK_ITEM_TYPE_NAME_TEST_CASE,
  WORK_ITEM_TYPE_ENUM_TEST_CASE,
  METADATA_KEYS,
} from '~/work_items/constants';
import {
  isAssigneesWidget,
  findLabelsWidget,
  findLinkedItemsWidget,
  canRouterNav,
} from '~/work_items/utils';
import { SUPPORT_BOT_USERNAME } from '~/issues/show/utils/issuable_data';

export default {
  components: {
    GlBadge,
    GlLink,
    GlIcon,
    GlLabel,
    GlFormCheckbox,
    GlSprintf,
    GlSkeletonLoader,
    IssuableAssignees,
    WorkItemTypeIcon,
    WorkItemPrefetch,
    WorkItemRelationshipIcons: () =>
      import('~/work_items/components/shared/work_item_relationship_icons.vue'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [timeagoMixin, glFeatureFlagMixin()],
  inject: {
    isGroup: {
      default: false,
    },
  },
  props: {
    hasScopedLabelsFeature: {
      type: Boolean,
      required: false,
      default: false,
    },
    issuableSymbol: {
      type: String,
      required: true,
    },
    fullPath: {
      type: String,
      required: false,
      default: null,
    },
    issuable: {
      type: Object,
      required: true,
    },
    labelFilterParam: {
      type: String,
      required: false,
      default: 'label_name',
    },
    showCheckbox: {
      type: Boolean,
      required: true,
    },
    checked: {
      type: Boolean,
      required: false,
      default: false,
    },
    showWorkItemTypeIcon: {
      type: Boolean,
      required: false,
      default: false,
    },
    isActive: {
      type: Boolean,
      required: false,
      default: false,
    },
    preventRedirect: {
      type: Boolean,
      required: false,
      default: false,
    },
    detailLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    hiddenMetadataKeys: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  constants: {
    METADATA_KEYS,
  },
  computed: {
    issuableId() {
      return getIdFromGraphQLId(this.issuable.id) || this.issuable.id;
    },
    issuableIid() {
      return this.issuable.iid;
    },
    workItemFullPath() {
      return (
        this.issuable.namespace?.fullPath || this.issuable.reference?.split(this.issuableSymbol)[0]
      );
    },
    isIncident() {
      return (
        this.issuable.workItemType?.name === WORK_ITEM_TYPE_NAME_INCIDENT ||
        this.issuable?.type === WORK_ITEM_TYPE_ENUM_INCIDENT
      );
    },
    isServiceDeskIssue() {
      return (
        (this.issuable?.type === WORK_ITEM_TYPE_ENUM_ISSUE ||
          this.issuable.workItemType?.name === WORK_ITEM_TYPE_NAME_ISSUE) &&
        this.issuable?.author?.username === SUPPORT_BOT_USERNAME
      );
    },
    isTestCase() {
      return (
        this.issuable.workItemType?.name === WORK_ITEM_TYPE_NAME_TEST_CASE ||
        this.issuable?.type === WORK_ITEM_TYPE_ENUM_TEST_CASE
      );
    },
    author() {
      return this.issuable.author || {};
    },
    externalAuthor() {
      return this.issuable.externalAuthor;
    },
    issuableLinkHref() {
      return this.issuable.webPath || this.issuable.gitlabWebUrl || this.issuable.webUrl;
    },
    authorId() {
      return getIdFromGraphQLId(this.author.id);
    },
    isIssuableUrlExternal() {
      return isExternal(this.issuableLinkHref ?? '');
    },
    reference() {
      return this.issuable.reference || `${this.issuableSymbol}${this.issuable.iid}`;
    },
    type() {
      return this.issuable.type || this.issuable.workItemType?.name.toUpperCase();
    },
    labels() {
      return (
        this.issuable.labels?.nodes ||
        this.issuable.labels ||
        findLabelsWidget(this.issuable)?.labels?.nodes ||
        []
      );
    },
    labelIdsString() {
      return JSON.stringify(this.labels.map((label) => getIdFromGraphQLId(label.id)));
    },
    assignees() {
      return (
        this.issuable.assignees?.nodes ||
        this.issuable.assignees ||
        this.issuable.widgets?.find(isAssigneesWidget)?.assignees?.nodes ||
        []
      );
    },
    linkedItemsWidget() {
      return findLinkedItemsWidget(this.issuable);
    },
    blockingCount() {
      return this.linkedItemsWidget?.blockingCount || 0;
    },
    blockedByCount() {
      return this.linkedItemsWidget?.blockedByCount || 0;
    },
    hasBlockingRelationships() {
      return this.blockingCount > 0 || this.blockedByCount > 0;
    },
    createdAt() {
      return this.issuable.createdAt ? this.timeFormatted(this.issuable.createdAt) : undefined;
    },
    isOpen() {
      return [STATUS_OPEN, STATE_OPEN].includes(this.issuable.state);
    },
    isClosed() {
      return [STATUS_CLOSED, STATE_CLOSED].includes(this.issuable.state);
    },
    statusTooltip() {
      return this.issuable.mergedAt ? this.tooltipTitle(this.issuable.mergedAt) : '';
    },
    timestamp() {
      return this.isClosed && this.issuable.closedAt
        ? this.issuable.closedAt
        : this.issuable.updatedAt;
    },
    formattedTimestamp() {
      if (this.isClosed && this.issuable.closedAt) {
        return sprintf(__('closed %{timeago}'), {
          timeago: this.timeFormatted(this.issuable.closedAt),
        });
      }
      if (this.issuable.updatedAt !== this.issuable.createdAt) {
        return sprintf(__('updated %{timeAgo}'), {
          timeAgo: this.timeFormatted(this.issuable.updatedAt),
        });
      }
      return undefined;
    },
    issuableTitleProps() {
      if (this.isIssuableUrlExternal) {
        return {
          target: '_blank',
        };
      }
      return {};
    },
    taskStatus() {
      const { completedCount, count } = this.issuable.taskCompletionStatus || {};
      if (!count) {
        return undefined;
      }

      return sprintf(
        n__(
          '%{completedCount} of %{count} checklist item completed',
          '%{completedCount} of %{count} checklist items completed',
          count,
        ),
        { completedCount, count },
      );
    },
    notesCount() {
      return this.issuable.userDiscussionsCount ?? this.issuable.userNotesCount;
    },
    showDiscussions() {
      return typeof this.notesCount === 'number';
    },
    showIssuableMeta() {
      return Boolean(
        this.hasSlotContents('status') ||
          this.hasSlotContents('statistics') ||
          this.showDiscussions ||
          this.issuable.assignees,
      );
    },
    statusBadgeVariant() {
      if (this.isMergeRequest && this.isClosed) {
        return 'danger';
      }

      return 'info';
    },
    isMergeRequest() {
      // eslint-disable-next-line no-underscore-dangle
      return this.issuable.__typename === 'MergeRequest';
    },
    issueAsWorkItem() {
      return (
        !this.isGroup &&
        // Use legacy view for unsupported work item types
        // incidents and Service Desk issues
        !this.isIncident &&
        !this.isServiceDeskIssue &&
        !this.isTestCase &&
        this.glFeatures.workItemViewForIssues
      );
    },
    hiddenIssuableTitle() {
      if (this.isMergeRequest) {
        return __('This merge request is hidden because its author has been banned.');
      }

      return __('This issue is hidden because its author has been banned.');
    },
    listItemUniqueId() {
      const availableFullPath = this.workItemFullPath || this.fullPath;
      return `listItem-${availableFullPath}/${getIdFromGraphQLId(this.issuable.id)}`;
    },
    isClickableLink() {
      return this.preventRedirect && !this.showCheckbox;
    },
  },
  methods: {
    hasSlotContents(slotName) {
      // eslint-disable-next-line @gitlab/vue-prefer-dollar-scopedslots
      return Boolean(this.$slots[slotName]);
    },
    scopedLabel(label) {
      const allowsScopedLabels =
        this.hasScopedLabelsFeature || findLabelsWidget(this.issuable)?.allowsScopedLabels;
      return allowsScopedLabels && isScopedLabel(label);
    },
    labelTitle(label) {
      return label.title || label.name;
    },
    labelTarget(label) {
      const value = encodeURIComponent(this.labelTitle(label));
      return `?${this.labelFilterParam}[]=${value}`;
    },
    handleIssuableItemClick(e) {
      if (e.metaKey || e.ctrlKey || e.shiftKey || this.showCheckbox || e.button === 1) {
        return;
      }
      e.preventDefault();
      // Unsupported types incidents and Service Desk issues
      // should not open in drawer
      if (this.isIncident || this.isServiceDeskIssue || this.isTestCase || !this.preventRedirect) {
        this.navigateToIssuable();
        return;
      }
      this.$emit('select-issuable', {
        id: this.issuable.id,
        iid: this.issuableIid,
        webUrl: this.issuable.webUrl,
        fullPath: this.workItemFullPath,
        workItemType: this.type.toLowerCase(),
      });
    },
    navigateToIssuable() {
      if (!this.fullPath) {
        visitUrl(this.issuableLinkHref);
      }
      const shouldRouterNav = canRouterNav({
        fullPath: this.fullPath,
        webUrl: this.issuableLinkHref,
        isGroup: this.isGroup,
        issueAsWorkItem: this.issueAsWorkItem,
      });

      if (shouldRouterNav) {
        this.$router.push({
          name: 'workItem',
          params: {
            iid: this.issuableIid,
          },
        });
      } else {
        visitUrl(this.issuableLinkHref);
      }
    },
    handleRowClick(e) {
      if (this.preventRedirect) {
        this.handleIssuableItemClick(e);
      }
    },
  },
};
</script>

<template>
  <li
    :id="`issuable_${issuableId}`"
    class="issue !gl-flex !gl-px-5"
    :class="{
      closed: issuable.closedAt,
      '!gl-bg-feedback-info': isActive,
      'issue-clickable gl-relative gl-cursor-pointer': isClickableLink,
      'hover:gl-bg-subtle': isClickableLink && !isActive,
    }"
    :data-labels="labelIdsString"
    :data-qa-issue-id="issuableId"
    data-testid="issuable-item-wrapper"
    @click="handleRowClick"
  >
    <a
      v-if="isClickableLink && issuableLinkHref"
      tabindex="-1"
      :href="issuableLinkHref"
      class="!gl-absolute gl-left-0 gl-top-0 !gl-z-1 !gl-flex gl-h-full gl-w-full"
      aria-hidden="true"
      data-testid="issuable-card-link-overlay"
    ></a>

    <gl-form-checkbox
      v-if="showCheckbox"
      class="gl-pr-3 gl-pt-2"
      :checked="checked"
      :data-id="issuableId"
      :data-iid="issuableIid"
      :data-type="type"
      @input="$emit('checked-input', $event)"
    >
      <span class="gl-sr-only">{{ issuable.title }}</span>
    </gl-form-checkbox>
    <div class="issuable-main-info">
      <div data-testid="issuable-title" class="issue-title title">
        <work-item-type-icon
          v-if="showWorkItemTypeIcon"
          class="gl-mr-2"
          :work-item-type="type"
          show-tooltip-on-hover
        />
        <button
          v-if="issuable.confidential"
          v-gl-tooltip
          :title="__('Confidential')"
          class="button-reset gl-mr-2 gl-inline-block gl-w-5"
          data-testid="confidential-icon-container"
        >
          <gl-icon name="eye-slash" />
        </button>
        <span
          v-if="issuable.hidden"
          v-gl-tooltip
          :title="hiddenIssuableTitle"
          class="gl-mr-2 gl-inline-block gl-w-5"
          data-testid="hidden-icon-container"
          :aria-label="__('Hidden')"
        >
          <gl-icon name="spam" />
        </span>
        <work-item-prefetch
          v-if="preventRedirect"
          :work-item-iid="issuableIid"
          :work-item-full-path="workItemFullPath"
          data-testid="issuable-prefetch-trigger"
        >
          <template #default="{ prefetchWorkItem, clearPrefetching }">
            <gl-link
              :id="listItemUniqueId"
              class="issue-title-text gl-text-base"
              dir="auto"
              :href="issuableLinkHref"
              data-testid="issuable-title-link"
              v-bind="issuableTitleProps"
              @click.stop="handleIssuableItemClick"
              @mouseover.native="prefetchWorkItem(issuableIid)"
              @mouseout.native="clearPrefetching"
            >
              {{ issuable.title }}
              <gl-icon v-if="isIssuableUrlExternal" name="external-link" class="gl-ml-2" />
            </gl-link>
          </template>
        </work-item-prefetch>
        <gl-link
          v-else
          :id="listItemUniqueId"
          class="issue-title-text gl-text-base"
          dir="auto"
          :href="issuableLinkHref"
          data-testid="issuable-title-link"
          v-bind="issuableTitleProps"
          @click.stop="handleIssuableItemClick"
        >
          {{ issuable.title }}
          <gl-icon v-if="isIssuableUrlExternal" name="external-link" class="gl-ml-2" />
        </gl-link>
        <slot v-if="hasSlotContents('title-icons')" name="title-icons"></slot>
        <span
          v-if="taskStatus"
          class="task-status gl-ml-2 gl-hidden gl-text-sm sm:!gl-inline-block"
          data-testid="task-status"
        >
          {{ taskStatus }}
        </span>
      </div>
      <div class="issuable-info">
        <slot v-if="hasSlotContents('reference')" name="reference"></slot>
        <span v-else data-testid="issuable-reference" class="issuable-reference">
          {{ reference }}
        </span>
        <span class="gl-hidden sm:gl-inline">
          <span aria-hidden="true">&middot;</span>
          <span class="issuable-authored gl-mr-3">
            <gl-sprintf v-if="author.name" :message="__('created %{timeAgo} by %{author}')">
              <template #timeAgo>
                <button
                  v-if="issuable.createdAt"
                  v-gl-tooltip.bottom
                  :title="tooltipTitle(issuable.createdAt)"
                  :aria-label="tooltipTitle(issuable.createdAt)"
                  data-testid="issuable-created-at"
                  class="button-reset gl-text-subtle"
                >
                  {{ createdAt }}
                </button>
              </template>
              <template #author>
                <span v-if="externalAuthor" data-testid="external-author"
                  >{{ externalAuthor }} {{ __('via') }}</span
                >
                <slot v-if="hasSlotContents('author')" name="author"></slot>
                <gl-link
                  v-else
                  :data-user-id="authorId"
                  :data-username="author.username"
                  :data-name="author.name"
                  :data-avatar-url="author.avatarUrl"
                  :href="author.webPath"
                  data-testid="issuable-author"
                  class="author-link js-user-link gl-text-sm !gl-text-subtle"
                  @click.stop
                >
                  <span class="author">{{ author.name }}</span>
                </gl-link>
              </template>
            </gl-sprintf>
            <gl-sprintf v-else :message="__('created %{timeAgo}')">
              <template #timeAgo>
                <span
                  v-if="issuable.createdAt"
                  v-gl-tooltip.bottom
                  :title="tooltipTitle(issuable.createdAt)"
                  data-testid="issuable-created-at"
                >
                  {{ createdAt }}
                </span>
              </template>
            </gl-sprintf>
          </span>
          <slot name="timeframe"></slot>
          <slot name="target-branch"></slot>
        </span>
        <p
          v-if="
            labels.length && !hiddenMetadataKeys.includes($options.constants.METADATA_KEYS.LABELS)
          "
          role="group"
          :aria-label="__('Labels')"
          class="gl-mb-0 gl-mt-1 gl-flex gl-flex-wrap gl-gap-2"
        >
          <gl-label
            v-for="(label, index) in labels"
            :key="index"
            :background-color="label.color"
            :title="labelTitle(label)"
            :description="label.description"
            :scoped="scopedLabel(label)"
            :target="labelTarget(label)"
            @click.stop
          />
        </p>
      </div>
    </div>
    <div class="issuable-meta gl-max-w-2/8 md:gl-max-w-3/8">
      <ul
        v-if="showIssuableMeta"
        class="controls gl-flex gl-max-w-full gl-flex-wrap-reverse gl-justify-end gl-gap-3 gl-gap-y-2"
      >
        <!-- eslint-disable-next-line @gitlab/vue-prefer-dollar-scopedslots -->
        <li v-if="$slots.status" data-testid="issuable-status" class="!gl-mr-0">
          <gl-badge
            v-if="!isOpen"
            v-gl-tooltip.top
            :variant="statusBadgeVariant"
            :title="statusTooltip"
          >
            <slot name="status"></slot>
          </gl-badge>
          <slot v-else name="status"></slot>
        </li>
        <slot name="pipeline-status"></slot>
        <li
          v-if="
            assignees.length &&
            !hiddenMetadataKeys.includes($options.constants.METADATA_KEYS.ASSIGNEE)
          "
          class="!gl-mr-0"
        >
          <issuable-assignees
            :assignees="assignees"
            :icon-size="16"
            :max-visible="4"
            class="gl-flex gl-items-center"
          />
        </li>
        <li v-else-if="detailLoading" class="!gl-mr-0">
          <gl-skeleton-loader :width="20" :lines="1" equal-width-lines />
        </li>
        <li class="!gl-mr-0 empty:gl-hidden">
          <slot name="reviewers"></slot>
        </li>
        <li class="!gl-mr-0 empty:gl-hidden">
          <slot name="approval-status"></slot>
        </li>
        <slot name="discussions">
          <li
            v-if="
              showDiscussions &&
              notesCount &&
              !hiddenMetadataKeys.includes($options.constants.METADATA_KEYS.COMMENTS)
            "
            class="!gl-mr-0 gl-hidden sm:gl-inline-flex"
            data-testid="issuable-comments"
          >
            <button
              v-gl-tooltip
              :title="__('Comments')"
              class="button-reset gl-flex gl-items-center !gl-text-inherit"
            >
              <gl-icon name="comments" class="gl-mr-2" />
              {{ notesCount }}
            </button>
          </li>
          <li v-else-if="detailLoading" class="!gl-mr-0">
            <gl-skeleton-loader :width="30" :lines="1" equal-width-lines />
          </li>
        </slot>
        <li
          v-if="!hiddenMetadataKeys.includes($options.constants.METADATA_KEYS.POPULARITY)"
          class="!gl-mr-0 [&:not(:has(li))]:gl-hidden"
        >
          <slot name="statistics"></slot>
        </li>
        <li
          v-if="
            isOpen &&
            hasBlockingRelationships &&
            !hiddenMetadataKeys.includes($options.constants.METADATA_KEYS.BLOCKED)
          "
          class="!gl-mr-0 empty:gl-hidden"
        >
          <work-item-relationship-icons
            :work-item-type="type"
            :work-item-full-path="workItemFullPath"
            :work-item-iid="issuableIid"
            :work-item-web-url="issuableLinkHref"
            :blocking-count="blockingCount"
            :blocked-by-count="blockedByCount"
          />
        </li>
        <li v-else-if="detailLoading" class="!gl-mr-0">
          <gl-skeleton-loader :width="45" :lines="1" equal-width-lines />
        </li>
        <slot name="custom-status"></slot>
      </ul>
      <div
        class="gl-hidden sm:gl-flex sm:gl-flex-col sm:gl-items-end md:gl-flex-row md:gl-items-center"
      >
        <slot name="health-status"></slot>
        <button
          v-if="timestamp"
          v-gl-tooltip.bottom
          :title="tooltipTitle(timestamp)"
          :aria-label="tooltipTitle(timestamp)"
          class="button-reset gl-text-subtle sm:gl-inline-block"
          data-testid="issuable-timestamp"
        >
          {{ formattedTimestamp }}
        </button>
      </div>
    </div>
  </li>
</template>
