<script>
import { isEmpty } from 'lodash';
import { GlAlert, GlSkeletonLoader, GlButton, GlTooltipDirective, GlEmptyState } from '@gitlab/ui';
import noAccessSvg from '@gitlab/svgs/dist/illustrations/analytics/no-access.svg?raw';
import { s__ } from '~/locale';
import { getParameterByName, updateHistory, setUrlParams } from '~/lib/utils/url_utility';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { isLoggedIn } from '~/lib/utils/common_utils';
import AbuseCategorySelector from '~/abuse_reports/components/abuse_category_selector.vue';
import { WORKSPACE_PROJECT } from '~/issues/constants';
import {
  i18n,
  WIDGET_TYPE_ASSIGNEES,
  WIDGET_TYPE_NOTIFICATIONS,
  WIDGET_TYPE_CURRENT_USER_TODOS,
  WIDGET_TYPE_DESCRIPTION,
  WIDGET_TYPE_AWARD_EMOJI,
  WIDGET_TYPE_HIERARCHY,
  WORK_ITEM_TYPE_VALUE_OBJECTIVE,
  WIDGET_TYPE_NOTES,
  WIDGET_TYPE_LINKED_ITEMS,
} from '../constants';

import workItemUpdatedSubscription from '../graphql/work_item_updated.subscription.graphql';
import updateWorkItemMutation from '../graphql/update_work_item.mutation.graphql';
import groupWorkItemByIidQuery from '../graphql/group_work_item_by_iid.query.graphql';
import workItemByIidQuery from '../graphql/work_item_by_iid.query.graphql';
import { findHierarchyWidgetChildren } from '../utils';

import WorkItemTree from './work_item_links/work_item_tree.vue';
import WorkItemActions from './work_item_actions.vue';
import WorkItemTodos from './work_item_todos.vue';
import WorkItemTitle from './work_item_title.vue';
import WorkItemAttributesWrapper from './work_item_attributes_wrapper.vue';
import WorkItemCreatedUpdated from './work_item_created_updated.vue';
import WorkItemDescription from './work_item_description.vue';
import WorkItemNotes from './work_item_notes.vue';
import WorkItemDetailModal from './work_item_detail_modal.vue';
import WorkItemAwardEmoji from './work_item_award_emoji.vue';
import WorkItemRelationships from './work_item_relationships/work_item_relationships.vue';
import WorkItemStickyHeader from './work_item_sticky_header.vue';
import WorkItemAncestors from './work_item_ancestors/work_item_ancestors.vue';

export default {
  i18n,
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  isLoggedIn: isLoggedIn(),
  components: {
    GlAlert,
    GlButton,
    GlSkeletonLoader,
    GlEmptyState,
    WorkItemActions,
    WorkItemTodos,
    WorkItemCreatedUpdated,
    WorkItemDescription,
    WorkItemAwardEmoji,
    WorkItemTitle,
    WorkItemAttributesWrapper,
    WorkItemTree,
    WorkItemNotes,
    WorkItemDetailModal,
    AbuseCategorySelector,
    WorkItemRelationships,
    WorkItemStickyHeader,
    WorkItemAncestors,
  },
  mixins: [glFeatureFlagMixin()],
  inject: ['fullPath', 'isGroup', 'reportAbusePath'],
  props: {
    isModal: {
      type: Boolean,
      required: false,
      default: false,
    },
    workItemIid: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      error: undefined,
      updateError: undefined,
      workItem: {},
      updateInProgress: false,
      modalWorkItemId: undefined,
      modalWorkItemIid: getParameterByName('work_item_iid'),
      isReportDrawerOpen: false,
      reportedUrl: '',
      reportedUserId: 0,
      isStickyHeaderShowing: false,
    };
  },
  apollo: {
    workItem: {
      query() {
        return this.isGroup ? groupWorkItemByIidQuery : workItemByIidQuery;
      },
      variables() {
        return {
          fullPath: this.fullPath,
          iid: this.workItemIid,
        };
      },
      skip() {
        return !this.workItemIid;
      },
      update(data) {
        return data.workspace.workItems.nodes[0] ?? {};
      },
      error() {
        this.setEmptyState();
      },
      result(res) {
        // need to handle this when the res is loading: true, netWorkStatus: 1, partial: true
        if (!res.data) {
          return;
        }
        this.$emit('work-item-updated', this.workItem);
        if (isEmpty(this.workItem)) {
          this.setEmptyState();
        }
        if (!this.isModal && this.workItem.namespace) {
          const path = this.workItem.namespace.fullPath
            ? ` · ${this.workItem.namespace.fullPath}`
            : '';

          document.title = `${this.workItem.title} · ${this.workItem?.workItemType?.name}${path}`;
        }
      },
      subscribeToMore: {
        document: workItemUpdatedSubscription,
        variables() {
          return {
            id: this.workItem.id,
          };
        },
        skip() {
          return !this.workItem?.id;
        },
      },
    },
  },
  computed: {
    workItemLoading() {
      return isEmpty(this.workItem) && this.$apollo.queries.workItem.loading;
    },
    workItemType() {
      return this.workItem.workItemType?.name;
    },
    workItemTypeId() {
      return this.workItem.workItemType?.id;
    },
    canUpdate() {
      return this.workItem.userPermissions?.updateWorkItem;
    },
    canDelete() {
      return this.workItem.userPermissions?.deleteWorkItem;
    },
    canSetWorkItemMetadata() {
      return this.workItem.userPermissions?.setWorkItemMetadata;
    },
    canAssignUnassignUser() {
      return this.workItemAssignees && this.canSetWorkItemMetadata;
    },
    workItemsMvc2Enabled() {
      return this.glFeatures.workItemsMvc2;
    },
    parentWorkItem() {
      return this.isWidgetPresent(WIDGET_TYPE_HIERARCHY)?.parent;
    },
    parentWorkItemConfidentiality() {
      return this.parentWorkItem?.confidential;
    },
    workItemIconName() {
      return this.workItem.workItemType?.iconName;
    },
    noAccessSvgPath() {
      return `data:image/svg+xml;utf8,${encodeURIComponent(noAccessSvg)}`;
    },
    hasDescriptionWidget() {
      return this.isWidgetPresent(WIDGET_TYPE_DESCRIPTION);
    },
    workItemNotificationsSubscribed() {
      return Boolean(this.isWidgetPresent(WIDGET_TYPE_NOTIFICATIONS)?.subscribed);
    },
    workItemCurrentUserTodos() {
      return this.isWidgetPresent(WIDGET_TYPE_CURRENT_USER_TODOS);
    },
    showWorkItemCurrentUserTodos() {
      return Boolean(this.$options.isLoggedIn && this.workItemCurrentUserTodos);
    },
    currentUserTodos() {
      return this.workItemCurrentUserTodos?.currentUserTodos?.nodes;
    },
    workItemAssignees() {
      return this.isWidgetPresent(WIDGET_TYPE_ASSIGNEES);
    },
    workItemAwardEmoji() {
      return this.isWidgetPresent(WIDGET_TYPE_AWARD_EMOJI);
    },
    workItemHierarchy() {
      return this.isWidgetPresent(WIDGET_TYPE_HIERARCHY);
    },
    workItemNotes() {
      return this.isWidgetPresent(WIDGET_TYPE_NOTES);
    },
    children() {
      return this.workItem ? findHierarchyWidgetChildren(this.workItem) : [];
    },
    workItemBodyClass() {
      return {
        'gl-pt-5': !this.updateError && !this.isModal,
      };
    },
    showIntersectionObserver() {
      return !this.isModal && this.workItemsMvc2Enabled;
    },
    hasLinkedWorkItems() {
      return this.glFeatures.linkedWorkItems;
    },
    workItemLinkedItems() {
      return this.isWidgetPresent(WIDGET_TYPE_LINKED_ITEMS);
    },
    showWorkItemLinkedItems() {
      return this.hasLinkedWorkItems && this.workItemLinkedItems;
    },
    titleClassHeader() {
      return {
        'gl-sm-display-none!': this.parentWorkItem,
        'gl-w-full': !this.parentWorkItem,
      };
    },
    titleClassComponent() {
      return {
        'gl-sm-display-block!': !this.parentWorkItem,
        'gl-display-none gl-sm-display-block!': this.parentWorkItem,
      };
    },
    headerWrapperClass() {
      return {
        'flex-wrap': this.parentWorkItem,
        'gl-display-block gl-md-display-flex! gl-align-items-flex-start gl-flex-direction-column gl-md-flex-direction-row gl-gap-3 gl-pt-3': true,
      };
    },
  },
  mounted() {
    if (this.modalWorkItemIid) {
      this.openInModal({
        event: undefined,
        modalWorkItem: { iid: this.modalWorkItemIid },
      });
    }
  },
  methods: {
    isWidgetPresent(type) {
      return this.workItem.widgets?.find((widget) => widget.type === type);
    },
    toggleConfidentiality(confidentialStatus) {
      this.updateInProgress = true;

      this.$apollo
        .mutate({
          mutation: updateWorkItemMutation,
          variables: {
            input: {
              id: this.workItem.id,
              confidential: confidentialStatus,
            },
          },
        })
        .then(
          ({
            data: {
              workItemUpdate: { errors, workItem },
            },
          }) => {
            if (errors?.length) {
              throw new Error(errors[0]);
            }

            this.$emit('workItemUpdated', {
              confidential: workItem?.confidential,
            });
          },
        )
        .catch((error) => {
          this.updateError = error.message;
        })
        .finally(() => {
          this.updateInProgress = false;
        });
    },
    setEmptyState() {
      this.error = this.$options.i18n.fetchError;
      document.title = s__('404|Not found');
    },
    updateHasNotes() {
      this.$emit('has-notes');
    },
    updateUrl(modalWorkItem) {
      updateHistory({
        url: setUrlParams({ work_item_iid: modalWorkItem?.iid }),
        replace: true,
      });
    },
    openInModal({ event, modalWorkItem }) {
      if (!this.workItemsMvc2Enabled) {
        return;
      }

      if (event) {
        event.preventDefault();

        this.updateUrl(modalWorkItem);
      }

      if (this.isModal) {
        this.$emit('update-modal', event, modalWorkItem);
        return;
      }
      this.modalWorkItemId = modalWorkItem.id;
      this.modalWorkItemIid = modalWorkItem.iid;
      this.$refs.modal.show();
    },
    openReportAbuseDrawer(reply) {
      if (this.isModal) {
        this.$emit('openReportAbuse', reply);
      } else {
        this.toggleReportAbuseDrawer(true, reply);
      }
    },
    toggleReportAbuseDrawer(isOpen, reply = {}) {
      this.isReportDrawerOpen = isOpen;
      this.reportedUrl = reply.url || {};
      this.reportedUserId = reply.author ? getIdFromGraphQLId(reply.author.id) : 0;
    },
    hideStickyHeader() {
      this.isStickyHeaderShowing = false;
    },
    showStickyHeader() {
      // only if scrolled under the work item's title
      if (this.$refs?.title?.$el.offsetTop < window.pageYOffset) {
        this.isStickyHeaderShowing = true;
      }
    },
  },
  WORK_ITEM_TYPE_VALUE_OBJECTIVE,
  WORKSPACE_PROJECT,
};
</script>

<template>
  <section>
    <section v-if="updateError" class="flash-container flash-container-page sticky">
      <gl-alert class="gl-mb-3" variant="danger" @dismiss="updateError = undefined">
        {{ updateError }}
      </gl-alert>
    </section>
    <section :class="workItemBodyClass">
      <div v-if="workItemLoading" class="gl-max-w-26 gl-py-5">
        <gl-skeleton-loader :height="65" :width="240">
          <rect width="240" height="20" x="5" y="0" rx="4" />
          <rect width="100" height="20" x="5" y="45" rx="4" />
        </gl-skeleton-loader>
      </div>
      <template v-else>
        <div class="gl-sm-display-none! gl-display-flex">
          <gl-button
            v-if="isModal"
            class="gl-ml-auto"
            category="tertiary"
            data-testid="work-item-close"
            icon="close"
            :aria-label="__('Close')"
            @click="$emit('close')"
          />
        </div>
        <div :class="headerWrapperClass">
          <work-item-ancestors v-if="parentWorkItem" :work-item="workItem" class="gl-mb-1" />
          <div
            v-if="!error && !workItemLoading"
            :class="titleClassHeader"
            data-testid="work-item-type"
          >
            <work-item-title
              v-if="workItem.title"
              ref="title"
              class="gl-sm-display-block!"
              :work-item-id="workItem.id"
              :work-item-title="workItem.title"
              :work-item-type="workItemType"
              :can-update="canUpdate"
              @error="updateError = $event"
            />
          </div>
          <div
            class="detail-page-header-actions gl-display-flex gl-align-self-start gl-ml-auto gl-gap-3"
          >
            <work-item-todos
              v-if="showWorkItemCurrentUserTodos"
              :work-item-id="workItem.id"
              :work-item-iid="workItemIid"
              :work-item-fullpath="fullPath"
              :current-user-todos="currentUserTodos"
              @error="updateError = $event"
            />
            <work-item-actions
              :full-path="fullPath"
              :work-item-id="workItem.id"
              :subscribed-to-notifications="workItemNotificationsSubscribed"
              :work-item-type="workItemType"
              :work-item-type-id="workItemTypeId"
              :can-delete="canDelete"
              :can-update="canUpdate"
              :is-confidential="workItem.confidential"
              :is-parent-confidential="parentWorkItemConfidentiality"
              :work-item-reference="workItem.reference"
              :work-item-create-note-email="workItem.createNoteEmail"
              :is-modal="isModal"
              :work-item-state="workItem.state"
              @deleteWorkItem="$emit('deleteWorkItem', { workItemType, workItemId: workItem.id })"
              @toggleWorkItemConfidentiality="toggleConfidentiality"
              @error="updateError = $event"
              @promotedToObjective="$emit('promotedToObjective', workItemIid)"
            />
          </div>
          <gl-button
            v-if="isModal"
            class="gl-display-none gl-sm-display-block!"
            category="tertiary"
            data-testid="work-item-close"
            icon="close"
            :aria-label="__('Close')"
            @click="$emit('close')"
          />
        </div>
        <div>
          <work-item-title
            v-if="workItem.title && parentWorkItem"
            ref="title"
            :class="titleClassComponent"
            :work-item-id="workItem.id"
            :work-item-title="workItem.title"
            :work-item-type="workItemType"
            :can-update="canUpdate"
            :use-h1="!isModal"
            @error="updateError = $event"
          />
          <work-item-created-updated
            :full-path="fullPath"
            :work-item-iid="workItemIid"
            :update-in-progress="updateInProgress"
          />
        </div>
        <work-item-sticky-header
          v-if="showIntersectionObserver"
          :current-user-todos="currentUserTodos"
          :show-work-item-current-user-todos="showWorkItemCurrentUserTodos"
          :parent-work-item-confidentiality="parentWorkItemConfidentiality"
          :update-in-progress="updateInProgress"
          :full-path="fullPath"
          :is-modal="isModal"
          :work-item="workItem"
          :is-sticky-header-showing="isStickyHeaderShowing"
          :work-item-notifications-subscribed="workItemNotificationsSubscribed"
          @hideStickyHeader="hideStickyHeader"
          @showStickyHeader="showStickyHeader"
          @deleteWorkItem="$emit('deleteWorkItem', { workItemType, workItemId: workItem.id })"
          @toggleWorkItemConfidentiality="toggleConfidentiality"
          @error="updateError = $event"
          @promotedToObjective="$emit('promotedToObjective', workItemIid)"
        />
        <div
          data-testid="work-item-overview"
          :class="{ 'work-item-overview': workItemsMvc2Enabled }"
        >
          <section>
            <work-item-attributes-wrapper
              :class="{ 'gl-md-display-none!': workItemsMvc2Enabled }"
              class="gl-border-b"
              :full-path="fullPath"
              :work-item="workItem"
              @error="updateError = $event"
            />
            <work-item-description
              v-if="hasDescriptionWidget"
              :full-path="fullPath"
              :work-item-id="workItem.id"
              :work-item-iid="workItem.iid"
              class="gl-pt-5"
              @error="updateError = $event"
            />
            <work-item-award-emoji
              v-if="workItemAwardEmoji"
              :work-item-id="workItem.id"
              :work-item-fullpath="fullPath"
              :award-emoji="workItemAwardEmoji.awardEmoji"
              :work-item-iid="workItemIid"
              @error="updateError = $event"
              @emoji-updated="$emit('work-item-emoji-updated', $event)"
            />
            <work-item-tree
              v-if="workItemType === $options.WORK_ITEM_TYPE_VALUE_OBJECTIVE"
              :full-path="fullPath"
              :work-item-type="workItemType"
              :parent-work-item-type="workItem.workItemType.name"
              :work-item-id="workItem.id"
              :work-item-iid="workItemIid"
              :children="children"
              :can-update="canUpdate"
              :confidential="workItem.confidential"
              @show-modal="openInModal"
              @addChild="$emit('addChild')"
            />
            <work-item-relationships
              v-if="showWorkItemLinkedItems"
              :work-item-id="workItem.id"
              :work-item-iid="workItemIid"
              :work-item-full-path="fullPath"
              :work-item-type="workItem.workItemType.name"
              @showModal="openInModal"
            />
            <work-item-notes
              v-if="workItemNotes"
              :full-path="fullPath"
              :work-item-id="workItem.id"
              :work-item-iid="workItem.iid"
              :work-item-type="workItemType"
              :is-modal="isModal"
              :assignees="workItemAssignees && workItemAssignees.assignees.nodes"
              :can-set-work-item-metadata="canAssignUnassignUser"
              :report-abuse-path="reportAbusePath"
              :is-work-item-confidential="workItem.confidential"
              class="gl-pt-5"
              :use-h2="!isModal"
              @error="updateError = $event"
              @has-notes="updateHasNotes"
              @openReportAbuse="openReportAbuseDrawer"
            />
            <gl-empty-state
              v-if="error"
              :title="$options.i18n.fetchErrorTitle"
              :description="error"
              :svg-path="noAccessSvgPath"
              :svg-height="null"
            />
          </section>
          <aside
            v-if="workItemsMvc2Enabled"
            data-testid="work-item-overview-right-sidebar"
            class="work-item-overview-right-sidebar gl-display-none gl-md-display-block"
            :class="{ 'is-modal': isModal }"
          >
            <work-item-attributes-wrapper
              :full-path="fullPath"
              :work-item="workItem"
              @error="updateError = $event"
            />
          </aside>
        </div>
      </template>
      <work-item-detail-modal
        v-if="!isModal"
        ref="modal"
        :work-item-id="modalWorkItemId"
        :work-item-iid="modalWorkItemIid"
        :show="true"
        @close="updateUrl"
        @openReportAbuse="toggleReportAbuseDrawer(true, $event)"
      />
      <abuse-category-selector
        v-if="isReportDrawerOpen"
        :reported-user-id="reportedUserId"
        :reported-from-url="reportedUrl"
        :show-drawer="true"
        @close-drawer="toggleReportAbuseDrawer(false)"
      />
    </section>
  </section>
</template>
