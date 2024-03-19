<script>
import '~/commons/bootstrap';
import { GlIcon, GlLink, GlTooltip, GlTooltipDirective, GlButton } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import IssueDueDate from '~/boards/components/issue_due_date.vue';
import { TYPENAME_WORK_ITEM } from '~/graphql_shared/constants';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { isMetaKey } from '~/lib/utils/common_utils';
import { setUrlParams, updateHistory } from '~/lib/utils/url_utility';
import { sprintf } from '~/locale';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import WorkItemDetailModal from '~/work_items/components/work_item_detail_modal.vue';
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
    IssueWeight: () => import('ee_component/boards/components/issue_card_weight.vue'),
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
        '<span class="bold">%{state}</span> %{timeInWords}<br/><span class="text-tertiary">%{timestamp}</span>',
        {
          state: this.stateText,
          timeInWords: this.stateTimeInWords,
          timestamp: this.stateTimestamp,
        },
      );
    },
    iconClasses() {
      return `${this.iconClass} ic-${this.iconName}`;
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
        if (isMetaKey(event)) {
          return;
        }
        event.preventDefault();
        this.$refs.modal.show();
        this.updateWorkItemIidUrlQuery(this.iid);
      }
    },
    handleWorkItemDeleted(workItemId) {
      this.$emit('relatedIssueRemoveRequest', workItemId);
    },
    updateWorkItemIidUrlQuery(iid) {
      updateHistory({
        url: setUrlParams({ work_item_iid: iid }),
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
    class="item-body gl-display-flex gl-align-items-center gl-gap-3"
  >
    <div
      class="item-contents gl-display-flex gl-align-items-center gl-flex-wrap gl-flex-grow-1 gl-gap-2 gl-px-3 gl-py-2 py-xl-0 flex-xl-nowrap gl-min-h-7"
    >
      <!-- Title area: Status icon (XL) and title -->
      <div class="item-title gl-display-flex gl-gap-3 gl-min-w-0">
        <gl-icon
          v-if="hasState"
          :id="`iconElementXL-${itemId}`"
          ref="iconElementXL"
          :class="iconClasses"
          :name="iconName"
          :title="stateTitle"
          :aria-label="state"
        />
        <gl-tooltip :target="`iconElementXL-${itemId}`">
          <span v-safe-html="stateTitle"></span>
        </gl-tooltip>
        <gl-icon
          v-if="confidential"
          v-gl-tooltip
          name="eye-slash"
          :title="__('Confidential')"
          class="confidential-icon"
          :aria-label="__('Confidential')"
        />
        <gl-link :href="computedPath" class="sortable-link" @click="handleTitleClick">
          {{ title }}
        </gl-link>
      </div>

      <!-- Info area: meta, path, and assignees -->
      <div
        class="item-info-area gl-display-flex gl-flex-grow-1 gl-flex-shrink-0 gl-gap-3 gl-ml-6 ml-xl-0"
      >
        <!-- Meta area: path and attributes -->
        <!-- If there is no room beside the path, meta attributes are put ABOVE it (gl-flex-wrap-reverse). -->
        <!-- See design: https://gitlab-org.gitlab.io/gitlab-design/hosted/pedro/%2383-issue-mr-rows-cards-spec-previews/#artboard16 -->
        <div
          class="item-meta gl-display-flex gl-md-justify-content-space-between gl-gap-3 gl-flex-wrap-reverse"
        >
          <!-- Path area: status icon (<XL), path, issue # -->
          <div
            class="item-path-area item-path-id gl-display-flex gl-align-items-center gl-flex-wrap gl-gap-3"
          >
            <gl-tooltip :target="() => $refs.iconElement">
              <span v-safe-html="stateTitle"></span>
            </gl-tooltip>
            <span
              v-if="itemPath"
              v-gl-tooltip
              :title="itemPath"
              class="path-id-text d-inline-block"
              >{{ itemPath }}</span
            >
            <span>{{ pathIdSeparator }}{{ itemId }}</span>
          </div>

          <!-- Attributes area: CI, epic count, weight, milestone -->
          <!-- They have a different order on large screen sizes -->
          <div
            class="item-attributes-area gl-display-flex gl-align-items-center gl-flex-wrap gl-gap-3"
          >
            <span v-if="hasPipeline" class="mr-ci-status order-md-last gl-md-ml-3 gl-mr-n2">
              <ci-icon :status="pipelineStatus" />
            </span>

            <issue-milestone
              v-if="hasMilestone"
              :milestone="milestone"
              class="item-milestone gl-font-sm gl-display-flex gl-align-items-center order-md-first gl-ml-2"
            />

            <!-- Flex order for slots is defined in the parent component: e.g. related_issues_block.vue -->
            <span v-if="weight > 0" class="order-md-1">
              <issue-weight
                :weight="weight"
                class="item-weight gl-display-flex gl-align-items-center"
                tag-name="span"
              />
            </span>

            <span v-if="dueDate" class="order-md-1">
              <issue-due-date
                :date="dueDate"
                :closed="Boolean(closedAt)"
                tooltip-placement="top"
                css-class="item-due-date gl-display-flex gl-align-items-center"
              />
            </span>

            <issue-assignees
              v-if="hasAssignees"
              :assignees="assignees"
              class="item-assignees gl-display-flex gl-align-items-center gl-align-self-end gl-flex-shrink-0 order-md-2"
            />
          </div>
        </div>
      </div>
    </div>

    <span
      v-if="isLocked"
      v-gl-tooltip
      class="gl-display-inline-block gl-cursor-not-allowed"
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
      @close="updateWorkItemIidUrlQuery"
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
