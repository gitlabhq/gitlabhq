<script>
import '~/commons/bootstrap';
import { GlIcon, GlLink, GlTooltip, GlTooltipDirective, GlButton } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import IssueDueDate from '~/boards/components/issue_due_date.vue';
import { TYPE_WORK_ITEM } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { isMetaKey } from '~/lib/utils/common_utils';
import { setUrlParams, updateHistory } from '~/lib/utils/url_utility';
import { sprintf } from '~/locale';
import CiIcon from '~/vue_shared/components/ci_icon.vue';
import WorkItemDetailModal from '~/work_items/components/work_item_detail_modal.vue';
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
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
  },
  mixins: [relatedIssuableMixin],
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
      return convertToGraphQLId(TYPE_WORK_ITEM, this.idKey);
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
        this.updateWorkItemIdUrlQuery(this.idKey);
      }
    },
    handleWorkItemDeleted(workItemId) {
      this.$emit('relatedIssueRemoveRequest', workItemId);
    },
    updateWorkItemIdUrlQuery(workItemId) {
      updateHistory({
        url: setUrlParams({ work_item_id: workItemId }),
        replace: true,
      });
    },
  },
};
</script>

<template>
  <div
    :class="{
      'issuable-info-container': !canReorder,
      'card-body': canReorder,
      'gl-pr-2': canRemove,
    }"
    class="item-body d-flex align-items-center gl-py-3 gl-px-5"
  >
    <div
      class="item-contents gl-display-flex gl-align-items-center gl-flex-wrap gl-flex-grow-1 flex-xl-nowrap gl-min-h-7"
    >
      <!-- Title area: Status icon (XL) and title -->
      <div class="item-title d-flex align-items-xl-center mb-xl-0 gl-min-w-0">
        <div ref="iconElementXL">
          <gl-icon
            v-if="hasState"
            ref="iconElementXL"
            class="gl-mr-3"
            :class="iconClasses"
            :name="iconName"
            :title="stateTitle"
            :aria-label="state"
          />
        </div>
        <gl-tooltip :target="() => $refs.iconElementXL">
          <span v-safe-html="stateTitle"></span>
        </gl-tooltip>
        <gl-icon
          v-if="confidential"
          v-gl-tooltip
          name="eye-slash"
          :title="__('Confidential')"
          class="confidential-icon gl-mr-2 align-self-baseline align-self-md-auto mt-xl-0"
          :aria-label="__('Confidential')"
        />
        <gl-link
          :href="computedPath"
          class="sortable-link gl-font-weight-normal"
          @click="handleTitleClick"
        >
          {{ title }}
        </gl-link>
      </div>

      <!-- Info area: meta, path, and assignees -->
      <div class="item-info-area d-flex flex-xl-grow-1 flex-shrink-0">
        <!-- Meta area: path and attributes -->
        <!-- If there is no room beside the path, meta attributes are put ABOVE it (flex-wrap-reverse). -->
        <!-- See design: https://gitlab-org.gitlab.io/gitlab-design/hosted/pedro/%2383-issue-mr-rows-cards-spec-previews/#artboard16 -->
        <div
          class="item-meta d-flex flex-wrap-reverse justify-content-start justify-content-md-between"
        >
          <!-- Path area: status icon (<XL), path, issue # -->
          <div
            class="item-path-area item-path-id d-flex align-items-center mr-2 mt-2 mt-xl-0 ml-xl-2"
          >
            <gl-tooltip :target="() => $refs.iconElement">
              <span v-safe-html="stateTitle"></span>
            </gl-tooltip>
            <span v-gl-tooltip :title="itemPath" class="path-id-text d-inline-block">{{
              itemPath
            }}</span>
            <span>{{ pathIdSeparator }}{{ itemId }}</span>
          </div>

          <!-- Attributes area: CI, epic count, weight, milestone -->
          <!-- They have a different order on large screen sizes -->
          <div class="item-attributes-area d-flex align-items-center mt-2 mt-xl-0">
            <span v-if="hasPipeline" class="mr-ci-status order-md-last">
              <a :href="pipelineStatus.details_path">
                <ci-icon v-gl-tooltip :status="pipelineStatus" :title="pipelineStatusTooltip" />
              </a>
            </span>

            <issue-milestone
              v-if="hasMilestone"
              :milestone="milestone"
              class="d-flex align-items-center item-milestone order-md-first ml-md-0"
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
              class="item-assignees align-items-center align-self-end flex-shrink-0 order-md-2 d-none d-md-flex"
            />
          </div>
        </div>

        <!-- Assignees. On small layouts, these are put here, at the end of the card. -->
        <issue-assignees
          v-if="assignees.length !== 0"
          :assignees="assignees"
          class="item-assignees d-flex align-items-center align-self-end flex-shrink-0 d-md-none gl-ml-3"
        />
      </div>
    </div>

    <span
      v-if="isLocked"
      v-gl-tooltip
      class="gl-px-3 gl-display-inline-block gl-cursor-not-allowed"
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
      :disabled="removeDisabled"
      class="js-issue-item-remove-button gl-ml-3"
      data-qa-selector="remove_related_issue_button"
      :title="__('Remove')"
      :aria-label="__('Remove')"
      @click="onRemoveRequest"
    />
    <work-item-detail-modal
      ref="modal"
      :work-item-id="workItemId"
      @close="updateWorkItemIdUrlQuery"
      @workItemDeleted="handleWorkItemDeleted"
    />
  </div>
</template>
