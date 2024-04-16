<script>
import { isEmpty } from 'lodash';
import { GlAlert, GlButton, GlTooltipDirective, GlEmptyState } from '@gitlab/ui';
import noAccessSvg from '@gitlab/svgs/dist/illustrations/analytics/no-access.svg?raw';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
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
  WORK_ITEM_TYPE_VALUE_EPIC,
  WIDGET_TYPE_NOTES,
  WIDGET_TYPE_LINKED_ITEMS,
  LINKED_ITEMS_ANCHOR,
} from '../constants';

import workItemUpdatedSubscription from '../graphql/work_item_updated.subscription.graphql';
import updateWorkItemMutation from '../graphql/update_work_item.mutation.graphql';
import groupWorkItemByIidQuery from '../graphql/group_work_item_by_iid.query.graphql';
import workItemByIidQuery from '../graphql/work_item_by_iid.query.graphql';
import { findHierarchyWidgetChildren } from '../utils';

import WorkItemTree from './work_item_links/work_item_tree.vue';
import WorkItemActions from './work_item_actions.vue';
import WorkItemTodos from './work_item_todos.vue';
import WorkItemNotificationsWidget from './work_item_notifications_widget.vue';
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
import WorkItemTitleWithEdit from './work_item_title_with_edit.vue';
import WorkItemLoading from './work_item_loading.vue';

export default {
  i18n,
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  isLoggedIn: isLoggedIn(),
  components: {
    GlAlert,
    GlButton,
    GlEmptyState,
    WorkItemActions,
    WorkItemTodos,
    WorkItemNotificationsWidget,
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
    WorkItemTitleWithEdit,
    WorkItemLoading,
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
      editMode: false,
      draftData: {},
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
    isDiscussionLocked() {
      return this.workItemNotes?.discussionLocked;
    },
    workItemsMvc2Enabled() {
      return this.glFeatures.workItemsMvc2;
    },
    newTodoAndNotificationsEnabled() {
      return this.glFeatures.notificationsTodosButtons;
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
      return !this.isModal && this.workItemsBetaEnabled && !this.editMode;
    },
    hasLinkedWorkItems() {
      return this.glFeatures.linkedWorkItems;
    },
    workItemLinkedItems() {
      return this.isWidgetPresent(WIDGET_TYPE_LINKED_ITEMS);
    },
    showWorkItemTree() {
      return [WORK_ITEM_TYPE_VALUE_OBJECTIVE, WORK_ITEM_TYPE_VALUE_EPIC].includes(
        this.workItemType,
      );
    },
    showWorkItemLinkedItems() {
      return this.hasLinkedWorkItems && this.workItemLinkedItems;
    },
    titleClassHeader() {
      return {
        'gl-sm-display-none! gl-mt-3': this.parentWorkItem,
        'gl-sm-display-block!': !this.parentWorkItem,
        'gl-w-full': !this.parentWorkItem && !this.editMode,
        'editable-wi-title': this.editMode && !this.parentWorkItem,
      };
    },
    titleClassComponent() {
      return {
        'gl-sm-display-block!': !this.parentWorkItem,
        'gl-display-none gl-sm-display-block! gl-mt-3': this.parentWorkItem,
        'editable-wi-title': this.workItemsMvc2Enabled,
      };
    },
    shouldShowEditButton() {
      return this.workItemsBetaEnabled && !this.editMode && this.canUpdate;
    },
    workItemsBetaEnabled() {
      return this.glFeatures.workItemsBeta;
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
    enableEditMode() {
      this.editMode = true;
    },
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
    openInModal({ event, modalWorkItem, context }) {
      if (!this.workItemsMvc2Enabled || context === LINKED_ITEMS_ANCHOR) {
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
    updateDraft(type, value) {
      this.draftData[type] = value;
    },
    async updateWorkItem() {
      this.updateInProgress = true;
      try {
        const {
          data: { workItemUpdate },
        } = await this.$apollo.mutate({
          mutation: updateWorkItemMutation,
          variables: {
            input: {
              id: this.workItem.id,
              title: this.draftData.title,
              descriptionWidget: {
                description: this.draftData.description,
              },
            },
          },
        });

        const { errors } = workItemUpdate;

        if (errors?.length) {
          this.updateError = errors.join('\n');
          throw new Error(this.updateError);
        }

        this.editMode = false;
      } catch (error) {
        Sentry.captureException(error);
      } finally {
        this.updateInProgress = false;
      }
    },
    cancelEditing() {
      this.draftData = {};
      this.editMode = false;
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
      <div v-if="workItemLoading">
        <work-item-loading :two-column-view="workItemsBetaEnabled" />
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
        <div
          class="gl-display-block gl-sm-display-flex! gl-align-items-flex-start gl-flex-direction-row gl-gap-3 gl-pt-3"
        >
          <work-item-ancestors v-if="parentWorkItem" :work-item="workItem" class="gl-mb-1" />
          <div
            v-if="!error && !workItemLoading"
            :class="titleClassHeader"
            data-testid="work-item-type"
          >
            <work-item-title-with-edit
              v-if="workItem.title && workItemsBetaEnabled"
              ref="title"
              :is-editing="editMode"
              :title="workItem.title"
              @updateWorkItem="updateWorkItem"
              @updateDraft="updateDraft('title', $event)"
            />
            <work-item-title
              v-else-if="workItem.title"
              ref="title"
              :work-item-id="workItem.id"
              :work-item-title="workItem.title"
              :work-item-type="workItemType"
              :can-update="canUpdate"
              @error="updateError = $event"
            />
          </div>
          <div class="gl-display-flex gl-align-self-start gl-ml-auto gl-gap-3">
            <gl-button
              v-if="shouldShowEditButton"
              category="secondary"
              data-testid="work-item-edit-form-button"
              @click="enableEditMode"
            >
              {{ __('Edit') }}
            </gl-button>
            <work-item-todos
              v-if="showWorkItemCurrentUserTodos"
              :work-item-id="workItem.id"
              :work-item-iid="workItemIid"
              :work-item-fullpath="fullPath"
              :current-user-todos="currentUserTodos"
              @error="updateError = $event"
            />
            <work-item-notifications-widget
              v-if="newTodoAndNotificationsEnabled"
              :full-path="fullPath"
              :work-item-id="workItem.id"
              :subscribed-to-notifications="workItemNotificationsSubscribed"
              :can-update="canUpdate"
              @error="updateError = $event"
            />
            <work-item-actions
              :full-path="fullPath"
              :work-item-id="workItem.id"
              :hide-subscribe="newTodoAndNotificationsEnabled"
              :subscribed-to-notifications="workItemNotificationsSubscribed"
              :work-item-type="workItemType"
              :work-item-type-id="workItemTypeId"
              :can-delete="canDelete"
              :can-update="canUpdate"
              :is-confidential="workItem.confidential"
              :is-discussion-locked="isDiscussionLocked"
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
          <work-item-title-with-edit
            v-if="workItem.title && workItemsBetaEnabled && parentWorkItem"
            ref="title"
            :is-editing="editMode"
            :class="titleClassComponent"
            :title="workItem.title"
            @updateWorkItem="updateWorkItem"
            @updateDraft="updateDraft('title', $event)"
          />
          <work-item-title
            v-else-if="workItem.title && parentWorkItem"
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
            v-if="!editMode"
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
          :class="{ 'work-item-overview': workItemsBetaEnabled }"
        >
          <section>
            <work-item-attributes-wrapper
              v-if="!workItemsBetaEnabled"
              :class="{ 'gl-md-display-none!': workItemsBetaEnabled }"
              class="gl-border-b"
              :full-path="fullPath"
              :work-item="workItem"
              @error="updateError = $event"
            />
            <work-item-description
              v-if="hasDescriptionWidget"
              :class="workItemsBetaEnabled ? '' : 'gl-pt-5'"
              :disable-inline-editing="workItemsBetaEnabled"
              :edit-mode="editMode"
              :full-path="fullPath"
              :work-item-id="workItem.id"
              :work-item-iid="workItem.iid"
              :update-in-progress="updateInProgress"
              @updateWorkItem="updateWorkItem"
              @updateDraft="updateDraft('description', $event)"
              @cancelEditing="cancelEditing"
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
          </section>
          <aside
            v-if="workItemsBetaEnabled"
            data-testid="work-item-overview-right-sidebar"
            class="work-item-overview-right-sidebar"
            :class="{ 'is-modal': isModal }"
          >
            <work-item-attributes-wrapper
              :full-path="fullPath"
              :work-item="workItem"
              @error="updateError = $event"
            />
          </aside>

          <work-item-tree
            v-if="showWorkItemTree"
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
            :is-discussion-locked="isDiscussionLocked"
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
