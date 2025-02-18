<script>
import '~/commons/bootstrap';
import { GlIcon, GlLink, GlTooltip, GlTooltipDirective, GlButton } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import IssueDueDate from '~/boards/components/issue_due_date.vue';
import { TYPENAME_WORK_ITEM } from '~/graphql_shared/constants';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { isModifierKey } from '~/lib/utils/common_utils';
import { setUrlParams, updateHistory } from '~/lib/utils/url_utility';
import { sprintf } from '~/locale';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import WorkItemDetailModal from '~/work_items/components/work_item_detail_modal.vue';
import { DETAIL_VIEW_QUERY_PARAM_NAME } from '~/work_items/constants';
import AbuseCategorySelector from '~/abuse_reports/components/abuse_category_selector.vue';
import relatedIssuableMixin from '../mixins/related_issuable_mixin';
import IssueAssignees from './issue_assignees.vue';
import IssueMilestone from './issue_milestone.vue';

export default {
  components: {
    IssueMilestone,
    IssueAssignees,
    CiIcon,
    GlIcon,
    GlLink,
    GlTooltip,
    IssueWeight: () => import('ee_component/issues/components/issue_weight.vue'),
    IssueDueDate,
    GlButton,
    WorkItemDetailModal,
    AbuseCategorySelector,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
  },
  mixins: [relatedIssuableMixin],
  inject: {
    reportAbusePath: {
      default: '',
    },
  },
  props: {
    canReorder: {
      type: Boolean,
      required: false,
      default: false,
    },
    isLocked: {
      type: Boolean,
      required: false,
      default: false,
    },
    lockedMessage: {
      type: String,
      required: false,
      default: '',
    },
    workItemType: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      isReportDrawerOpen: false,
      reportedUserId: 0,
      reportedUrl: '',
    };
  },
  computed: {
    stateTitle() {
      return sprintf(
        '<span class="gl-font-bold">%{state}</span> %{timeInWords}<br/><span class="gl-text-tertiary">%{timestamp}</span>',
        {
          state: this.stateText,
          timeInWords: this.stateTimeInWords,
          timestamp: this.stateTimestamp,
        },
      );
    },
    workItemId() {
      return convertToGraphQLId(TYPENAME_WORK_ITEM, this.idKey);
    },
    workItemIid() {
      return String(this.iid);
    },
  },
  methods: {
    handleTitleClick(event) {
      if (this.workItemType === 'TASK') {
        if (isModifierKey(event)) {
          return;
        }
        event.preventDefault();
        this.$refs.modal.show();
        this.updateQueryParam(this.idKey);
      }
    },
    handleWorkItemDeleted(workItemId) {
      this.$emit('relatedIssueRemoveRequest', workItemId);
    },
    updateQueryParam(id) {
      updateHistory({
        url: setUrlParams({ [DETAIL_VIEW_QUERY_PARAM_NAME]: id }),
        replace: true,
      });
    },
    toggleReportAbuseDrawer(isOpen, reply = {}) {
      this.isReportDrawerOpen = isOpen;
      this.reportedUrl = reply.url;
      this.reportedUserId = reply.author ? getIdFromGraphQLId(reply.author.id) : 0;
    },
    openReportAbuseDrawer(reply) {
      this.toggleReportAbuseDrawer(true, reply);
    },
  },
};
</script>

<template>
  <div
    :class="{
      'issuable-info-container': !canReorder,
      'card-body': canReorder,
    }"
    class="item-body gl-flex gl-items-center gl-gap-3"
  >
    <div
      class="item-contents py-xl-0 flex-xl-nowrap gl-flex gl-min-h-7 gl-grow gl-flex-wrap gl-items-center gl-gap-2 gl-px-3 gl-py-2"
    >
      <!-- Title area: Status icon (XL) and title -->
      <div class="item-title gl-flex gl-min-w-0 gl-gap-3">
        <gl-icon
          v-if="hasState"
          :id="`iconElementXL-${itemId}`"
          ref="iconElementXL"
          class="issue-token-state-icon"
          :name="iconName"
          :title="stateTitle"
          :aria-label="state"
          :variant="iconVariant"
        />
        <gl-tooltip :target="`iconElementXL-${itemId}`">
          <span v-safe-html="stateTitle"></span>
        </gl-tooltip>
        <gl-icon
          v-if="confidential"
          v-gl-tooltip
          name="eye-slash"
          :title="__('Confidential')"
          :aria-label="__('Confidential')"
          variant="warning"
        />
        <gl-link :href="computedPath" class="sortable-link" @click="handleTitleClick">
          {{ title }}
        </gl-link>
      </div>

      <!-- Info area: meta, path, and assignees -->
      <div class="item-info-area ml-xl-0 gl-ml-6 gl-flex gl-shrink-0 gl-grow gl-gap-3">
        <!-- Meta area: path and attributes -->
        <!-- If there is no room beside the path, meta attributes are put ABOVE it (gl-flex-wrap-reverse). -->
        <!-- See design: https://gitlab-org.gitlab.io/gitlab-design/hosted/pedro/%2383-issue-mr-rows-cards-spec-previews/#artboard16 -->
        <div class="item-meta gl-flex gl-flex-wrap-reverse gl-gap-3 md:gl-justify-between">
          <!-- Path area: status icon (<XL), path, issue # -->
          <div class="item-path-area item-path-id gl-flex gl-flex-wrap gl-items-center gl-gap-3">
            <gl-tooltip :target="() => $refs.iconElement">
              <span v-safe-html="stateTitle"></span>
            </gl-tooltip>
            <span
              v-if="itemPath"
              v-gl-tooltip
              :title="itemPath"
              class="path-id-text gl-inline-block"
              >{{ itemPath }}</span
            >
            <span>{{ pathIdSeparator }}{{ itemId }}</span>
          </div>

          <!-- Attributes area: CI, epic count, weight, milestone -->
          <!-- They have a different order on large screen sizes -->
          <div class="item-attributes-area gl-flex gl-items-center gl-gap-3">
            <span v-if="hasPipeline" class="mr-ci-status order-md-last -gl-mr-2 md:gl-ml-3">
              <ci-icon :status="pipelineStatus" />
            </span>

            <issue-milestone
              v-if="hasMilestone"
              :milestone="milestone"
              class="item-milestone order-md-first gl-ml-2 gl-flex gl-items-center gl-text-sm"
            />

            <!-- Flex order for slots is defined in the parent component: e.g. related_issues_block.vue -->
            <span v-if="weight > 0" class="order-md-1">
              <issue-weight :weight="weight" class="item-weight gl-items-center" />
            </span>

            <span v-if="dueDate" class="order-md-1">
              <issue-due-date
                :date="dueDate"
                :closed="Boolean(closedAt)"
                tooltip-placement="top"
                css-class="item-due-date gl-flex gl-items-center"
              />
            </span>

            <issue-assignees
              v-if="hasAssignees"
              :assignees="assignees"
              class="item-assignees order-md-2 gl-flex gl-shrink-0 gl-items-center gl-self-end"
            />
          </div>
        </div>
      </div>
    </div>

    <span
      v-if="isLocked"
      v-gl-tooltip
      class="gl-inline-block gl-cursor-not-allowed"
      :title="lockedMessage"
      data-testid="lockIcon"
    >
      <gl-icon name="lock" />
    </span>
    <gl-button
      v-else-if="canRemove"
      v-gl-tooltip
      icon="close"
      category="tertiary"
      size="small"
      :disabled="removeDisabled"
      class="js-issue-item-remove-button gl-mr-2"
      data-testid="remove-related-issue-button"
      :title="__('Remove')"
      :aria-label="__('Remove')"
      @click="onRemoveRequest"
    />
    <work-item-detail-modal
      ref="modal"
      :work-item-id="workItemId"
      :work-item-iid="workItemIid"
      @close="updateQueryParam"
      @workItemDeleted="handleWorkItemDeleted"
      @openReportAbuse="openReportAbuseDrawer"
    />
    <abuse-category-selector
      v-if="isReportDrawerOpen && reportAbusePath"
      :reported-user-id="reportedUserId"
      :reported-from-url="reportedUrl"
      :show-drawer="isReportDrawerOpen"
      @close-drawer="toggleReportAbuseDrawer(false)"
    />
  </div>
</template>
