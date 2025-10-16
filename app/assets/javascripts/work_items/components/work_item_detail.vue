<script>
import { isEmpty } from 'lodash';
import {
  GlAlert,
  GlButton,
  GlTooltipDirective,
  GlEmptyState,
  GlIntersectionObserver,
} from '@gitlab/ui';
import noAccessSvg from '@gitlab/svgs/dist/illustrations/empty-state/empty-search-md.svg';
import DuoWorkflowAction from 'ee_component/ai/components/duo_workflow_action.vue';
import DesignDropzone from '~/vue_shared/components/upload_dropzone/upload_dropzone.vue';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { s__, __ } from '~/locale';
import { InternalEvents } from '~/tracking';
import { getParameterByName, updateHistory, removeParams } from '~/lib/utils/url_utility';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import toast from '~/vue_shared/plugins/global_toast';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { WORKSPACE_PROJECT } from '~/issues/constants';
import { addShortcutsExtension } from '~/behaviors/shortcuts';
import { sanitize } from '~/lib/dompurify';
import { shouldDisableShortcuts } from '~/behaviors/shortcuts/shortcuts_toggle';
import { keysFor, ISSUABLE_EDIT_DESCRIPTION } from '~/behaviors/shortcuts/keybindings';
import ShortcutsWorkItems from '~/behaviors/shortcuts/shortcuts_work_items';
import {
  i18n,
  WIDGET_TYPE_ASSIGNEES,
  WIDGET_TYPE_CURRENT_USER_TODOS,
  WIDGET_TYPE_DESCRIPTION,
  WIDGET_TYPE_AWARD_EMOJI,
  WIDGET_TYPE_HIERARCHY,
  WORK_ITEM_TYPE_NAME_OBJECTIVE,
  WIDGET_TYPE_NOTES,
  WIDGET_TYPE_LINKED_ITEMS,
  WIDGET_TYPE_DESIGNS,
  WORK_ITEM_REFERENCE_CHAR,
  WORK_ITEM_TYPE_NAME_EPIC,
  WIDGET_TYPE_DEVELOPMENT,
  STATE_OPEN,
  WIDGET_TYPE_ERROR_TRACKING,
  WIDGET_TYPE_ITERATION,
  WIDGET_TYPE_LINKED_RESOURCES,
  WIDGET_TYPE_MILESTONE,
  WORK_ITEM_TYPE_NAME_INCIDENT,
} from '../constants';

import workItemUpdatedSubscription from '../graphql/work_item_updated.subscription.graphql';
import updateWorkItemMutation from '../graphql/update_work_item.mutation.graphql';
import workItemByIdQuery from '../graphql/work_item_by_id.query.graphql';
import workItemByIidQuery from '../graphql/work_item_by_iid.query.graphql';
import getAllowedWorkItemChildTypes from '../graphql/work_item_allowed_children.query.graphql';
import workspacePermissionsQuery from '../graphql/workspace_permissions.query.graphql';
import { findHierarchyWidgetDefinition, activeWorkItemIds } from '../utils';
import { updateWorkItemCurrentTodosWidget } from '../graphql/cache_utils';

import getWorkItemDesignListQuery from './design_management/graphql/design_collection.query.graphql';
import uploadDesignMutation from './design_management/graphql/upload_design.mutation.graphql';
import { designUploadOptimisticResponse } from './design_management/utils';
import { updateStoreAfterUploadDesign } from './design_management/cache_updates';
import {
  MAXIMUM_FILE_UPLOAD_LIMIT,
  MAXIMUM_FILE_UPLOAD_LIMIT_REACHED,
  designUploadSkippedWarning,
  UPLOAD_DESIGN_ERROR_MESSAGE,
  ALERT_VARIANTS,
  VALID_DESIGN_FILE_MIMETYPE,
} from './design_management/constants';

import WorkItemTree from './work_item_links/work_item_tree.vue';
import WorkItemActions from './work_item_actions.vue';
import TodosToggle from './shared/todos_toggle.vue';
import WorkItemNotificationsWidget from './work_item_notifications_widget.vue';
import WorkItemAttributesWrapper from './work_item_attributes_wrapper.vue';
import WorkItemCreatedUpdated from './work_item_created_updated.vue';
import WorkItemDescription from './work_item_description.vue';
import WorkItemNotes from './work_item_notes.vue';
import WorkItemAwardEmoji from './work_item_award_emoji.vue';
import WorkItemRelationships from './work_item_relationships/work_item_relationships.vue';
import WorkItemStickyHeader from './work_item_sticky_header.vue';
import WorkItemAncestors from './work_item_ancestors/work_item_ancestors.vue';
import WorkItemTitle from './work_item_title.vue';
import WorkItemLoading from './work_item_loading.vue';
import WorkItemAbuseModal from './work_item_abuse_modal.vue';
import WorkItemDrawer from './work_item_drawer.vue';
import DesignWidget from './design_management/design_management_widget.vue';
import DesignUploadButton from './design_management/upload_button.vue';
import WorkItemDevelopment from './work_item_development/work_item_development.vue';
import WorkItemCreateBranchMergeRequestSplitButton from './work_item_development/work_item_create_branch_merge_request_split_button.vue';
import WorkItemMetadataProvider from './work_item_metadata_provider.vue';

const defaultWorkspacePermissions = {
  createDesign: false,
  updateDesign: false,
  moveDesign: false,
};

const trackingMixin = InternalEvents.mixin();

export default {
  name: 'WorkItemDetail',
  i18n,
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  isLoggedIn: isLoggedIn(),
  VALID_DESIGN_FILE_MIMETYPE,
  SHOW_SIDEBAR_STORAGE_KEY: 'work_item_show_sidebar',
  ENABLE_TRUNCATION_STORAGE_KEY: 'work_item_truncate_descriptions',
  components: {
    DesignDropzone,
    DesignWidget,
    DesignUploadButton,
    GlAlert,
    GlButton,
    GlEmptyState,
    GlIntersectionObserver,
    LocalStorageSync,
    WorkItemActions,
    TodosToggle,
    WorkItemNotificationsWidget,
    WorkItemCreatedUpdated,
    WorkItemDescription,
    WorkItemAwardEmoji,
    WorkItemAttributesWrapper,
    WorkItemTree,
    WorkItemNotes,
    WorkItemRelationships,
    WorkItemErrorTracking: () => import('~/work_items/components/work_item_error_tracking.vue'),
    WorkItemLinkedResources: () => import('~/work_items/components/work_item_linked_resources.vue'),
    WorkItemStickyHeader,
    WorkItemAncestors,
    WorkItemTitle,
    WorkItemLoading,
    WorkItemAbuseModal,
    WorkItemDrawer,
    WorkItemDevelopment,
    WorkItemCreateBranchMergeRequestSplitButton,
    WorkItemVulnerabilities: () =>
      import('ee_component/work_items/components/work_item_vulnerabilities.vue'),
    WorkItemMetadataProvider,
    DuoWorkflowAction,
  },
  mixins: [glFeatureFlagMixin(), trackingMixin],
  inject: {
    groupPath: {
      from: 'groupPath',
    },
    hasSubepicsFeature: {
      from: 'hasSubepicsFeature',
    },
    hasLinkedItemsEpicsFeature: {
      from: 'hasLinkedItemsEpicsFeature',
    },
    duoRemoteFlowsAvailability: {
      from: 'duoRemoteFlowsAvailability',
      default: false,
    },
    isGroup: {},
  },
  props: {
    isModal: {
      type: Boolean,
      required: false,
      default: false,
    },
    workItemId: {
      type: String,
      required: false,
      default: null,
    },
    workItemIid: {
      type: String,
      required: false,
      default: null,
    },
    workItemFullPath: {
      type: String,
      required: false,
      default: '',
    },
    isDrawer: {
      type: Boolean,
      required: false,
      default: false,
    },
    isBoard: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      error: undefined,
      updateError: undefined,
      workItem: {},
      updateInProgress: false,
      isReportModalOpen: false,
      reportedUrl: '',
      reportedUserId: 0,
      isStickyHeaderShowing: false,
      editMode: false,
      draftData: {},
      filesToBeSaved: [],
      allowedChildTypes: [],
      designUploadError: null,
      designUploadErrorVariant: ALERT_VARIANTS.danger,
      workspacePermissions: defaultWorkspacePermissions,
      activeChildItem: null,
      isEmptyStateVisible: false,
      dragCounter: 0,
      isDesignUploadButtonInViewport: false,
      isDragDataValid: false,
      isAddingNotes: false,
      info: getParameterByName('resolves_discussion'),
      showSidebar: true,
      truncationEnabled: true,
      lastRealtimeUpdatedAt: new Date(),
      refetchError: null,
    };
  },
  apollo: {
    workItem: {
      query() {
        if (this.workItemId) {
          return workItemByIdQuery;
        }
        return workItemByIidQuery;
      },
      variables() {
        if (this.workItemId) {
          return {
            id: this.workItemId,
          };
        }
        return {
          fullPath: this.workItemFullPath,
          iid: this.workItemIid,
        };
      },
      skip() {
        return !this.workItemIid && !this.workItemId;
      },
      update(data) {
        if (this.workItemId) {
          return data.workItem ?? {};
        }
        return data.workspace?.workItem ?? {};
      },
      error() {
        if (this.workItem?.id === this.workItemId || this.workItem?.iid === this.workItemIid) {
          this.refetchError = s__(
            'WorkItem|Your data might be out of date. Refresh to see the latest information.',
          );
          return;
        }
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
          return;
        }
        if (!res.error) {
          this.error = null;
          this.refetchError = null;
        }

        if (!(this.isModal || this.isDrawer) && this.workItem.namespace) {
          const path = this.workItem.namespace.fullPath
            ? ` · ${this.workItem.namespace.fullPath}`
            : '';

          document.title = `${this.workItem.title} (${WORK_ITEM_REFERENCE_CHAR}${this.workItem.iid}) · ${this.workItem?.workItemType?.name}${path}`;
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
    workspacePermissions: {
      query: workspacePermissionsQuery,
      variables() {
        return {
          fullPath: this.workItemFullPath,
        };
      },
      skip() {
        return this.isGroup || this.workItemLoading;
      },
      update(data) {
        return data.workspace?.userPermissions ?? defaultWorkspacePermissions;
      },
    },
  },
  computed: {
    workItemProjectId() {
      return this.workItem?.project?.id;
    },
    workItemLoading() {
      return isEmpty(this.workItem) && this.$apollo.queries.workItem.loading;
    },
    workItemType() {
      return this.workItem.workItemType?.name;
    },
    workItemTypeId() {
      return this.workItem.workItemType?.id;
    },
    workItemAuthorId() {
      return getIdFromGraphQLId(this.workItem.author?.id);
    },
    canUpdate() {
      return this.workItem.userPermissions?.updateWorkItem;
    },
    canUpdateChildren() {
      return this.workItem.userPermissions?.adminParentLink;
    },
    canDelete() {
      return this.workItem.userPermissions?.deleteWorkItem;
    },
    canMove() {
      return this.workItem.userPermissions?.moveWorkItem;
    },
    canReportSpam() {
      return this.workItem.userPermissions?.reportSpam;
    },
    canUpdateMetadata() {
      return this.workItem.userPermissions?.setWorkItemMetadata;
    },
    canAdminWorkItemLink() {
      return this.workItem.userPermissions?.adminWorkItemLink;
    },
    canAssignUnassignUser() {
      return this.workItemAssignees && this.canUpdateMetadata;
    },
    canSummarizeComments() {
      return this.workItem.userPermissions?.summarizeComments;
    },
    hasBlockedWorkItemsFeature() {
      return this.workItem.userPermissions?.blockedWorkItems;
    },
    canCreateNote() {
      return this.workItem.userPermissions?.createNote;
    },
    isDiscussionLocked() {
      return this.workItemNotes?.discussionLocked;
    },
    workItemsAlphaEnabled() {
      return this.glFeatures.workItemsAlpha;
    },
    newTodoAndNotificationsEnabled() {
      return this.glFeatures.notificationsTodosButtons;
    },
    parentWorkItem() {
      return this.findWidget(WIDGET_TYPE_HIERARCHY)?.parent;
    },
    parentWorkItemId() {
      return this.parentWorkItem?.id;
    },
    hasParent() {
      const { workItemType, parentWorkItem, hasSubepicsFeature } = this;

      if (workItemType === WORK_ITEM_TYPE_NAME_EPIC) {
        return Boolean(hasSubepicsFeature && parentWorkItem);
      }

      return Boolean(parentWorkItem);
    },
    shouldShowAncestors() {
      // Checks whether current work item has parent
      // or it is in hierarchy but there is no permission to view the parent
      return this.hasParent || this.workItemHierarchy?.hasParent;
    },
    parentWorkItemConfidentiality() {
      return this.parentWorkItem?.confidential;
    },
    hasDescriptionWidget() {
      return this.findWidget(WIDGET_TYPE_DESCRIPTION);
    },
    hasDesignWidget() {
      return this.findWidget(WIDGET_TYPE_DESIGNS) && (this.$router || this.isBoard);
    },
    showUploadDesign() {
      return this.hasDesignWidget && this.canAddDesign;
    },
    canReorderDesign() {
      return this.hasDesignWidget && this.workspacePermissions.moveDesign;
    },
    workItemCurrentUserTodos() {
      return this.findWidget(WIDGET_TYPE_CURRENT_USER_TODOS);
    },
    showWorkItemCurrentUserTodos() {
      return Boolean(this.$options.isLoggedIn && this.workItemCurrentUserTodos);
    },
    currentUserTodos() {
      return this.workItemCurrentUserTodos?.currentUserTodos?.nodes;
    },
    workItemAssignees() {
      return this.findWidget(WIDGET_TYPE_ASSIGNEES);
    },
    workItemAwardEmoji() {
      return this.findWidget(WIDGET_TYPE_AWARD_EMOJI);
    },
    workItemErrorTracking() {
      return this.findWidget(WIDGET_TYPE_ERROR_TRACKING) ?? {};
    },
    workItemLinkedResources() {
      return this.findWidget(WIDGET_TYPE_LINKED_RESOURCES)?.linkedResources.nodes ?? [];
    },
    workItemHierarchy() {
      return this.findWidget(WIDGET_TYPE_HIERARCHY);
    },
    workItemNotes() {
      return this.findWidget(WIDGET_TYPE_NOTES);
    },
    workItemDevelopment() {
      return this.findWidget(WIDGET_TYPE_DEVELOPMENT);
    },
    workItemIteration() {
      return this.findWidget(WIDGET_TYPE_ITERATION)?.iteration;
    },
    workItemMilestone() {
      return this.findWidget(WIDGET_TYPE_MILESTONE)?.milestone;
    },
    workItemBodyClass() {
      return {
        'gl-pt-5': !this.updateError && !this.isModal,
      };
    },
    flashNoticeMessage() {
      const numberOfDiscussionsResolved = getParameterByName('resolves_discussion');
      return numberOfDiscussionsResolved === 'all'
        ? __('Resolved all discussions.')
        : __('Resolved 1 discussion.');
    },
    showIntersectionObserver() {
      return !this.isModal && !this.editMode;
    },
    workItemLinkedItems() {
      return this.workItemType === WORK_ITEM_TYPE_NAME_EPIC
        ? this.findWidget(WIDGET_TYPE_LINKED_ITEMS) && this.hasLinkedItemsEpicsFeature
        : this.findWidget(WIDGET_TYPE_LINKED_ITEMS);
    },
    showWorkItemTree() {
      return this.findWidget(WIDGET_TYPE_HIERARCHY) && this.allowedChildTypes?.length > 0;
    },
    titleClassHeader() {
      return {
        '@sm/panel:!gl-hidden !gl-mt-3': this.shouldShowAncestors,
        '@sm/panel:!gl-block': !this.shouldShowAncestors,
        'gl-w-full': !this.shouldShowAncestors && !this.editMode,
        'editable-wi-title': this.editMode && !this.shouldShowAncestors,
      };
    },
    titleClassComponent() {
      return {
        '@sm/panel:!gl-block': !this.shouldShowAncestors,
        'gl-hidden @sm/panel:!gl-block !gl-mt-3': this.shouldShowAncestors,
        'editable-wi-title': this.workItemsAlphaEnabled,
      };
    },
    shouldShowEditButton() {
      return !this.editMode && this.canUpdate;
    },
    editShortcutKey() {
      return shouldDisableShortcuts() ? null : keysFor(ISSUABLE_EDIT_DESCRIPTION)[0];
    },
    editTooltip() {
      const description = __('Edit title and description');
      const key = this.editShortcutKey;
      return shouldDisableShortcuts()
        ? description
        : sanitize(`${description} <kbd class="flat gl-ml-1" aria-hidden=true>${key}</kbd>`);
    },
    modalCloseButtonClass() {
      return {
        '@sm/panel:gl-hidden': !this.error,
        'gl-flex': true,
      };
    },
    workItemPresent() {
      return !isEmpty(this.workItem);
    },
    isSaving() {
      return this.filesToBeSaved.length > 0;
    },
    designCollectionQueryBody() {
      return {
        query: getWorkItemDesignListQuery,
        variables: { id: this.workItem.id, atVersion: null },
      };
    },
    iid() {
      return this.workItemIid || this.workItem.iid;
    },
    widgets() {
      return this.workItem.widgets;
    },
    isItemSelected() {
      return !isEmpty(this.activeChildItem);
    },
    activeChildItemType() {
      return this.activeChildItem?.workItemType?.name;
    },
    activeChildItemId() {
      return this.activeChildItem?.id;
    },
    workItemIsOpen() {
      return this.workItem?.state === STATE_OPEN;
    },
    showCreateBranchMergeRequestSplitButton() {
      return this.workItemDevelopment && this.workItemIsOpen;
    },
    namespaceFullName() {
      return this.workItem?.namespace?.fullName || '';
    },
    contextualViewEnabled() {
      return this.workItemsAlphaEnabled || this.glFeatures?.workItemViewForIssues;
    },
    hasChildren() {
      return this.workItemHierarchy?.hasChildren;
    },
    isModalOrDrawer() {
      return this.isModal || this.isDrawer;
    },
    workItemActionProps() {
      return {
        fullPath: this.workItemFullPath,
        workItemId: this.workItem.id,
        hideSubscribe: this.newTodoAndNotificationsEnabled,
        workItemType: this.workItemType,
        workItemIid: this.iid,
        projectId: this.workItemProjectId,
        canDelete: this.canDelete,
        canReportSpam: this.canReportSpam,
        canUpdate: this.canUpdate,
        canUpdateMetadata: this.canUpdateMetadata,
        canMove: this.canMove && !this.workItem.movedToWorkItemUrl,
        isConfidential: this.workItem.confidential,
        isDiscussionLocked: this.isDiscussionLocked,
        isParentConfidential: this.parentWorkItemConfidentiality,
        workItemReference: this.workItem.reference,
        workItemWebUrl: this.workItem.webUrl,
        workItemCreateNoteEmail: this.workItem.createNoteEmail,
        isModal: this.isModalOrDrawer,
        workItemState: this.workItem.state,
        hasChildren: this.hasChildren,
        hasParent: this.shouldShowAncestors,
        parentId: this.parentWorkItemId,
        workItemAuthorId: this.workItemAuthorId,
        canCreateRelatedItem: this.workItemLinkedItems !== undefined,
        isGroup: this.isGroup,
        widgets: this.widgets,
        allowedChildTypes: this.allowedChildTypes,
        namespaceFullName: this.namespaceFullName,
        showSidebar: this.showSidebar,
        truncationEnabled: this.truncationEnabled,
      };
    },
    canAddDesign() {
      return this.workspacePermissions.createDesign;
    },
    canUpdateDesign() {
      return this.workspacePermissions.updateDesign;
    },
    canPasteDesign() {
      return !this.isSaving && !this.isAddingNotes && !this.editMode && !this.activeChildItem;
    },
    isDuoWorkflowEnabled() {
      return this.duoRemoteFlowsAvailability && this.glFeatures.duoWorkflowInCi;
    },
    agentPrivileges() {
      return [1, 2, 3, 4, 5];
    },
    confidentialityToggledText() {
      return this.workItem.confidential
        ? s__('WorkItem|Confidentiality turned on.')
        : s__('WorkItem|Confidentiality turned off.');
    },
  },
  watch: {
    'workItem.id': {
      immediate: true,
      async handler(newId) {
        if (newId) {
          activeWorkItemIds.value.push(newId);
        }
        // Update allowedChildTypes using manual query instead of a smart query to prevent cache inconsistency (issue: #521771)
        const { workItem } = await this.fetchAllowedChildTypes(newId);
        this.allowedChildTypes = workItem
          ? findHierarchyWidgetDefinition(workItem)?.allowedChildTypes?.nodes
          : [];
      },
    },
  },
  beforeDestroy() {
    document.removeEventListener('actioncable:reconnected', this.refetchIfStale);
    activeWorkItemIds.value = activeWorkItemIds.value.filter((id) => id !== this.workItem.id);
  },
  mounted() {
    addShortcutsExtension(ShortcutsWorkItems);
    document.addEventListener('actioncable:reconnected', this.refetchIfStale);
  },
  methods: {
    async fetchAllowedChildTypes(workItemId) {
      if (!workItemId) return { workItem: null };

      try {
        const { data } = await this.$apollo.query({
          query: getAllowedWorkItemChildTypes,
          variables: { id: workItemId },
        });

        return data;
      } catch (error) {
        return { workItem: null };
      }
    },
    handleWorkItemCreated() {
      this.$apollo.queries.workItem.refetch();
    },
    enableEditMode() {
      this.editMode = true;
    },
    findWidget(type) {
      return this.workItem?.widgets?.find((widget) => widget.type === type);
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
            toast(this.confidentialityToggledText);
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
    openContextualView({ event, modalWorkItem }) {
      if (!modalWorkItem) {
        this.activeChildItem = null;
        return;
      }

      if (
        !this.contextualViewEnabled ||
        modalWorkItem.workItemType?.name === WORK_ITEM_TYPE_NAME_INCIDENT ||
        this.isDrawer
      ) {
        return;
      }
      if (event) {
        event.preventDefault();
      }

      if (this.isModal) {
        this.$emit('update-modal', event, modalWorkItem);
        return;
      }

      if (this.activeChildItem && this.activeChildItem.iid === modalWorkItem.iid) {
        this.activeChildItem = null;
      } else {
        this.activeChildItem = modalWorkItem;
      }
    },
    openReportAbuseModal(reply) {
      if (this.isModal) {
        this.$emit('openReportAbuse', reply);
      } else {
        this.toggleReportAbuseModal(true, reply);
      }
    },
    toggleReportAbuseModal(isOpen, workItem = this.workItem) {
      this.isReportModalOpen = isOpen;
      this.reportedUrl = workItem.webUrl || workItem.url || {};
      this.reportedUserId = workItem.author ? getIdFromGraphQLId(workItem.author.id) : 0;
    },
    hideStickyHeader() {
      this.isStickyHeaderShowing = false;
    },
    showStickyHeader() {
      this.isStickyHeaderShowing = true;
    },
    updateDraft(type, value) {
      this.draftData[type] = value;
    },
    async updateWorkItem({ clearDraft } = {}) {
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

        if (clearDraft) {
          clearDraft();
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
    isValidDesignUpload(files) {
      if (!this.canAddDesign) return false;

      if (files.length > MAXIMUM_FILE_UPLOAD_LIMIT) {
        this.designUploadError = MAXIMUM_FILE_UPLOAD_LIMIT_REACHED;

        return false;
      }
      return true;
    },
    onUploadDesign(files) {
      // Redirect to latest version before uploading to avoid cache reading errors
      if (this.$route?.query?.version) {
        this.$router.push({
          path: this.$route.path,
          query: {},
        });
      }

      // convert to Array so that we have Array methods (.map, .some, etc.)
      this.filesToBeSaved = Array.from(files);
      if (!this.isValidDesignUpload(this.filesToBeSaved)) return null;

      const mutationPayload = {
        optimisticResponse: designUploadOptimisticResponse(this.filesToBeSaved),
        variables: {
          files: this.filesToBeSaved,
          projectPath: this.workItemFullPath,
          iid: this.iid,
        },
        context: {
          hasUpload: true,
        },
        mutation: uploadDesignMutation,
        update: this.afterUploadDesign,
      };

      this.designUploadErrorVariant = ALERT_VARIANTS.danger;
      return this.$apollo
        .mutate(mutationPayload)
        .then((res) => this.onUploadDesignDone(res))
        .catch((error) => this.onUploadDesignError(error));
    },
    afterUploadDesign(store, { data: { designManagementUpload } }) {
      updateStoreAfterUploadDesign(store, designManagementUpload, this.designCollectionQueryBody);
    },
    resetFilesToBeSaved() {
      this.filesToBeSaved = [];
    },
    onUploadDesignDone(res) {
      // display any warnings, if necessary
      const skippedFiles = res?.data?.designManagementUpload?.skippedDesigns || [];
      const skippedWarningMessage = designUploadSkippedWarning(this.filesToBeSaved, skippedFiles);
      if (skippedWarningMessage) {
        this.designUploadError = skippedWarningMessage;
        this.designUploadErrorVariant = ALERT_VARIANTS.info;
      }

      // reset state
      this.resetFilesToBeSaved();
    },
    onUploadDesignError(error) {
      Sentry.captureException(error);
      this.resetFilesToBeSaved();
      this.designUploadError = UPLOAD_DESIGN_ERROR_MESSAGE;
    },
    updateWorkItemCurrentTodosWidgetCache({ cache, todos }) {
      updateWorkItemCurrentTodosWidget({
        cache,
        todos,
        fullPath: this.workItemFullPath,
        iid: this.iid,
      });
    },
    async deleteChildItem({ id }) {
      this.activeChildItem = null;
      await this.$nextTick();

      const { cache } = this.$apollo.provider.clients.defaultClient;
      cache.evict({
        id: cache.identify({
          __typename: 'WorkItem',
          id,
        }),
      });
      cache.gc();
    },
    workItemTypeChanged() {
      this.$apollo.queries.workItem.refetch();
      this.$emit('workItemTypeChanged', this.workItem);
    },
    isValidDragDataType({ dataTransfer }) {
      this.isDragDataValid = Array.from(dataTransfer.items).some((item) =>
        this.$options.VALID_DESIGN_FILE_MIMETYPE.mimetype.includes(item.type),
      );
    },
    preventDefaultConditionally(event) {
      const $refs = this.$refs.workItemNotes?.$el.$refs;
      const topForm = $refs.addNoteTop;
      const bottomForm = $refs.addNoteBottom;

      if (!topForm?.contains(event.target) && !bottomForm?.contains(event.target)) {
        event.preventDefault();
      }
    },
    onDragEnter(event) {
      this.dragCounter += 1;
      this.isValidDragDataType(event);
    },
    onDragOver(event) {
      this.isValidDragDataType(event);
      if (this.isDesignUploadButtonInViewport) this.isEmptyStateVisible = true;
    },
    onDragLeaveMain(event) {
      // Check if the drag is leaving the main container entirely
      const mainContainerRef = this.$refs.workItemDetail;
      if (!mainContainerRef.contains(event.relatedTarget)) {
        this.dragCounter = 0;
        this.isEmptyStateVisible = false; // Hide dropzone
      }
    },
    onDrop() {
      this.dragCounter = 0; // Reset drag state
      this.isEmptyStateVisible = false; // Hide dropzone after drop
    },
    dismissInfo() {
      this.info = undefined;
      updateHistory({ url: removeParams(['resolves_discussion']) });
    },
    handleToggleSidebar() {
      this.showSidebar = !this.showSidebar;
      this.trackEvent('change_work_item_sidebar_visibility', {
        label: this.showSidebar.toString(), // New sidebar visibility
      });
    },
    handleTruncationEnabled() {
      this.truncationEnabled = !this.truncationEnabled;
      this.trackEvent('change_work_item_description_truncation', {
        label: this.truncationEnabled.toString(), // New user truncation setting
      });
    },
    refetchIfStale() {
      const now = new Date();
      const staleThreshold = 5 * 60 * 1000; // 5 minutes in milliseconds
      if (now - this.lastRealtimeUpdatedAt > staleThreshold) {
        this.$apollo.queries.workItem.refetch();
        this.lastRealtimeUpdatedAt = now;
      }
    },
  },
  WORK_ITEM_TYPE_NAME_OBJECTIVE,
  WORKSPACE_PROJECT,
  noAccessSvg,
};
</script>

<template>
  <work-item-metadata-provider :full-path="workItemFullPath">
    <div
      ref="workItemDetail"
      class="work-item-detail"
      data-testid="work-item-detail"
      @dragstart="preventDefaultConditionally"
      @dragend="preventDefaultConditionally"
      @dragenter.prevent.stop="onDragEnter"
      @dragover.prevent.stop="onDragOver"
      @dragleave.prevent.stop="onDragLeaveMain"
      @drop.prevent.stop="onDrop"
    >
      <work-item-sticky-header
        v-if="showIntersectionObserver"
        :current-user-todos="currentUserTodos"
        :show-work-item-current-user-todos="showWorkItemCurrentUserTodos"
        :parent-work-item-confidentiality="parentWorkItemConfidentiality"
        :full-path="workItemFullPath"
        :is-modal="isModal"
        :is-drawer="isDrawer"
        :work-item="workItem"
        :is-sticky-header-showing="isStickyHeaderShowing"
        @hideStickyHeader="hideStickyHeader"
        @showStickyHeader="showStickyHeader"
        @deleteWorkItem="$emit('deleteWorkItem', { workItemType, workItemId: workItem.id })"
        @toggleWorkItemConfidentiality="toggleConfidentiality"
        @error="updateError = $event"
        @promotedToObjective="$emit('promotedToObjective', iid)"
        @workItemTypeChanged="workItemTypeChanged"
        @toggleEditMode="enableEditMode"
        @workItemStateUpdated="$emit('workItemStateUpdated')"
        @toggleReportAbuseModal="toggleReportAbuseModal"
        @todosUpdated="updateWorkItemCurrentTodosWidgetCache"
      >
        <template #actions>
          <work-item-actions
            v-if="workItemPresent"
            v-bind="workItemActionProps"
            :update-in-progress="updateInProgress"
            @deleteWorkItem="$emit('deleteWorkItem', { workItemType, workItemId: workItem.id })"
            @toggleWorkItemConfidentiality="toggleConfidentiality"
            @error="updateError = $event"
            @promotedToObjective="$emit('promotedToObjective', iid)"
            @workItemStateUpdated="$emit('workItemStateUpdated')"
            @workItemTypeChanged="workItemTypeChanged"
            @toggleReportAbuseModal="toggleReportAbuseModal"
            @workItemCreated="handleWorkItemCreated"
            @toggleSidebar="handleToggleSidebar"
            @toggleTruncationEnabled="handleTruncationEnabled"
          />
        </template>
      </work-item-sticky-header>
      <section class="work-item-view">
        <component :is="isModalOrDrawer ? 'h2' : 'h1'" v-if="editMode" class="gl-sr-only">{{
          s__('WorkItem|Edit work item')
        }}</component>
        <gl-alert
          v-if="info"
          class="gl-mb-3"
          variant="info"
          data-testid="info-alert"
          @dismiss="dismissInfo"
        >
          {{ flashNoticeMessage }}
        </gl-alert>
        <section v-if="updateError" class="flash-container flash-container-page sticky">
          <gl-alert class="gl-mb-3" variant="danger" @dismiss="updateError = undefined">
            {{ updateError }}
          </gl-alert>
        </section>
        <section
          v-if="refetchError"
          :class="isDrawer ? 'gl-sticky gl-top-0' : 'flash-container flash-container-page sticky'"
          :style="{ zIndex: 100 }"
          data-testid="work-item-refetch-alert"
        >
          <gl-alert class="gl-mb-3" variant="warning" @dismiss="refetchError = null">
            <span>{{ refetchError }}</span>
            <gl-button
              class="gl-ml-2"
              category="primary"
              variant="confirm"
              size="small"
              @click="$apollo.queries.workItem.refetch()"
            >
              {{ __('Refresh') }}
            </gl-button>
          </gl-alert>
        </section>
        <section :class="workItemBodyClass">
          <div :class="modalCloseButtonClass">
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
          <work-item-loading v-if="workItemLoading" />
          <gl-empty-state
            v-else-if="error"
            :title="s__('WorkItem|Work item not found')"
            :description="error"
            :svg-path="$options.noAccessSvg"
          />
          <div v-else data-testid="detail-wrapper">
            <div class="gl-block gl-flex-row gl-items-start gl-gap-3 @sm/panel:!gl-flex">
              <work-item-ancestors
                v-if="shouldShowAncestors"
                :work-item="workItem"
                class="gl-mb-1"
              />
              <div v-if="!error" :class="titleClassHeader" data-testid="work-item-type">
                <work-item-title
                  v-if="workItem.title"
                  ref="title"
                  :is-editing="editMode"
                  :is-modal="isModalOrDrawer"
                  :title="workItem.title"
                  :title-html="workItem.titleHtml"
                  @updateWorkItem="updateWorkItem"
                  @updateDraft="updateDraft('title', $event)"
                  @error="updateError = $event"
                />
              </div>
              <div class="gl-ml-auto gl-mt-1 gl-flex gl-gap-3 gl-self-start">
                <gl-button
                  v-if="shouldShowEditButton"
                  v-gl-tooltip.bottom.html
                  :title="editTooltip"
                  category="secondary"
                  data-testid="work-item-edit-form-button"
                  class="shortcut-edit-wi-description"
                  @click="enableEditMode"
                >
                  {{ __('Edit') }}
                </gl-button>
                <todos-toggle
                  v-if="showWorkItemCurrentUserTodos"
                  :item-id="workItem.id"
                  :current-user-todos="currentUserTodos"
                  todos-button-type="secondary"
                  @todosUpdated="updateWorkItemCurrentTodosWidgetCache"
                  @error="updateError = $event"
                />
                <work-item-notifications-widget
                  v-if="newTodoAndNotificationsEnabled"
                  :work-item-id="workItem.id"
                  @error="updateError = $event"
                />
                <work-item-actions
                  v-if="workItemPresent"
                  v-bind="workItemActionProps"
                  :update-in-progress="updateInProgress"
                  @deleteWorkItem="
                    $emit('deleteWorkItem', { workItemType, workItemId: workItem.id })
                  "
                  @toggleWorkItemConfidentiality="toggleConfidentiality"
                  @error="updateError = $event"
                  @promotedToObjective="$emit('promotedToObjective', iid)"
                  @workItemStateUpdated="$emit('workItemStateUpdated')"
                  @workItemTypeChanged="workItemTypeChanged"
                  @toggleReportAbuseModal="toggleReportAbuseModal"
                  @workItemCreated="handleWorkItemCreated"
                  @toggleSidebar="handleToggleSidebar"
                  @toggleTruncationEnabled="handleTruncationEnabled"
                />
              </div>
              <gl-button
                v-if="isModal"
                class="gl-hidden @sm/panel:!gl-block"
                category="tertiary"
                data-testid="work-item-close"
                icon="close"
                :aria-label="__('Close')"
                @click="$emit('close')"
              />
            </div>
            <div>
              <work-item-title
                v-if="workItem.title && shouldShowAncestors"
                ref="title"
                :is-editing="editMode"
                :is-modal="isModalOrDrawer"
                :class="titleClassComponent"
                :title="workItem.title"
                :title-html="workItem.titleHtml"
                @error="updateError = $event"
                @updateWorkItem="updateWorkItem"
                @updateDraft="updateDraft('title', $event)"
              />
              <div class="gl-flex gl-items-center gl-gap-3">
                <work-item-created-updated
                  v-if="!editMode"
                  :full-path="workItemFullPath"
                  :work-item-iid="iid"
                  class="gl-grow"
                />
                <div
                  v-if="!showSidebar"
                  class="work-item-container-xs-hidden gl-hidden @md/panel:gl-block"
                >
                  <gl-button
                    size="small"
                    category="secondary"
                    data-testid="work-item-show-sidebar-button"
                    icon="sidebar-right"
                    @click="handleToggleSidebar"
                  >
                    {{ s__('WorkItem|Show sidebar') }}
                  </gl-button>
                </div>
              </div>
            </div>
            <div
              data-testid="work-item-overview"
              class="work-item-overview"
              :class="{ 'sidebar-hidden': !showSidebar }"
            >
              <section>
                <local-storage-sync
                  v-model="truncationEnabled"
                  :storage-key="$options.ENABLE_TRUNCATION_STORAGE_KEY"
                />
                <work-item-description
                  v-if="hasDescriptionWidget"
                  :edit-mode="editMode"
                  :full-path="workItemFullPath"
                  :is-group="isGroup"
                  :work-item-id="workItem.id"
                  :work-item-iid="workItem.iid"
                  :update-in-progress="updateInProgress"
                  :without-heading-anchors="isDrawer"
                  :hide-fullscreen-markdown-button="isDrawer"
                  :truncation-enabled="truncationEnabled"
                  @updateWorkItem="updateWorkItem"
                  @updateDraft="updateDraft('description', $event)"
                  @cancelEditing="cancelEditing"
                  @error="updateError = $event"
                />
                <div class="gl-mt-3 gl-flex gl-flex-wrap gl-justify-between gl-gap-y-3">
                  <work-item-award-emoji
                    v-if="workItemAwardEmoji"
                    :work-item-archived="workItem.archived"
                    :work-item-discussion-locked="isDiscussionLocked"
                    :work-item-id="workItem.id"
                    :work-item-fullpath="workItemFullPath"
                    :award-emoji="workItemAwardEmoji.awardEmoji"
                    :work-item-iid="iid"
                    @error="updateError = $event"
                    @emoji-updated="$emit('work-item-emoji-updated', $event)"
                  />
                  <div class="gl-mt-2 gl-flex gl-flex-wrap gl-gap-3 gl-gap-y-3">
                    <gl-intersection-observer
                      v-if="showUploadDesign"
                      @appear="isDesignUploadButtonInViewport = true"
                      @disappear="isDesignUploadButtonInViewport = false"
                    >
                      <design-upload-button
                        v-if="showUploadDesign"
                        :is-saving="isSaving"
                        data-testid="design-upload-button"
                        @upload="onUploadDesign"
                        @error="onUploadDesignError"
                      />
                    </gl-intersection-observer>
                    <work-item-create-branch-merge-request-split-button
                      v-if="showCreateBranchMergeRequestSplitButton"
                      :work-item-iid="iid"
                      :work-item-full-path="workItemFullPath"
                      :work-item-type="workItem.workItemType.name"
                      :is-confidential-work-item="workItem.confidential"
                      :project-id="workItemProjectId"
                    />
                    <div>
                      <duo-workflow-action
                        v-if="isDuoWorkflowEnabled"
                        :project-path="workItemFullPath"
                        :hover-message="__('Generate merge request with Duo')"
                        :goal="workItem.webUrl"
                        workflow-definition="issue_to_merge_request"
                        :agent-privileges="agentPrivileges"
                        size="medium"
                        >{{ __('Generate MR with Duo') }}</duo-workflow-action
                      >
                    </div>
                  </div>
                </div>
              </section>
              <local-storage-sync
                v-model="showSidebar"
                :storage-key="$options.SHOW_SIDEBAR_STORAGE_KEY"
              />
              <section
                data-testid="work-item-overview-right-sidebar"
                class="work-item-overview-right-sidebar"
                :class="{ 'is-modal': isModal, '@md/panel:gl-hidden': !showSidebar }"
              >
                <h2 class="gl-sr-only">{{ s__('WorkItem|Attributes') }}</h2>
                <work-item-attributes-wrapper
                  :class="{ 'gl-top-9': isDrawer }"
                  :full-path="workItemFullPath"
                  :work-item="workItem"
                  :group-path="groupPath"
                  :is-group="isGroup"
                  @error="updateError = $event"
                  @attributesUpdated="$emit('attributesUpdated', $event)"
                />
              </section>

              <work-item-error-tracking
                v-if="workItemErrorTracking.identifier"
                :full-path="workItemFullPath"
                :iid="iid"
              />

              <work-item-linked-resources
                v-if="workItemLinkedResources.length"
                :linked-resources="workItemLinkedResources"
              />

              <design-widget
                v-if="hasDesignWidget"
                :class="{ 'gl-mt-0': isDrawer }"
                :work-item-id="workItem.id"
                :work-item-iid="iid"
                :work-item-full-path="workItemFullPath"
                :work-item-web-url="workItem.webUrl"
                :is-group="isGroup"
                :upload-error="designUploadError"
                :upload-error-variant="designUploadErrorVariant"
                :is-saving="isSaving"
                :can-reorder-design="canReorderDesign"
                :is-board="isBoard"
                :can-add-design="canAddDesign"
                :can-update-design="canUpdateDesign"
                :can-paste-design="canPasteDesign"
                @upload="onUploadDesign"
                @dismissError="designUploadError = null"
              >
                <template #empty-state>
                  <design-dropzone
                    v-if="isEmptyStateVisible && !isSaving && isDragDataValid && !isAddingNotes"
                    class="gl-relative gl-mt-5"
                    show-upload-design-overlay
                    validate-design-upload-on-dragover
                    hide-upload-text-on-dragging
                    :accept-design-formats="$options.VALID_DESIGN_FILE_MIMETYPE.mimetype"
                    @change="onUploadDesign"
                  >
                    <template #upload-text>
                      {{ s__('DesignManagement|Drag images here to add designs.') }}
                    </template>
                  </design-dropzone>
                </template>
              </design-widget>

              <work-item-tree
                v-if="showWorkItemTree"
                :full-path="workItemFullPath"
                :is-group="isGroup"
                :work-item-type="workItemType"
                :parent-work-item-type="workItem.workItemType.name"
                :work-item-id="workItem.id"
                :work-item-iid="iid"
                :parent-iteration="workItemIteration"
                :parent-milestone="workItemMilestone"
                :active-child-item-id="activeChildItemId"
                :can-update="canUpdate"
                :can-update-children="canUpdateChildren"
                :confidential="workItem.confidential"
                :allowed-child-types="allowedChildTypes"
                :is-drawer="isDrawer"
                :contextual-view-enabled="contextualViewEnabled"
                @show-modal="openContextualView"
                @addChild="$emit('addChild')"
              />
              <work-item-relationships
                v-if="workItemLinkedItems"
                :is-group="isGroup"
                :work-item-id="workItem.id"
                :work-item-iid="iid"
                :work-item-full-path="workItemFullPath"
                :work-item-type="workItem.workItemType.name"
                :can-admin-work-item-link="canAdminWorkItemLink"
                :active-child-item-id="activeChildItemId"
                :has-blocked-work-items-feature="hasBlockedWorkItemsFeature"
                :contextual-view-enabled="contextualViewEnabled"
                @showModal="openContextualView"
              />

              <work-item-development
                v-if="workItemDevelopment"
                :is-modal="isModal"
                :work-item-id="workItem.id"
                :work-item-iid="iid"
                :work-item-full-path="workItemFullPath"
              />

              <work-item-vulnerabilities
                :work-item-iid="iid"
                :work-item-full-path="workItemFullPath"
                data-testid="work-item-vulnerabilities"
              />

              <work-item-notes
                v-if="workItemNotes"
                ref="workItemNotes"
                :full-path="workItemFullPath"
                :work-item-id="workItem.id"
                :work-item-iid="workItem.iid"
                :work-item-type="workItemType"
                :work-item-type-id="workItemTypeId"
                :is-modal="isModal"
                :is-drawer="isDrawer"
                :assignees="workItemAssignees && workItemAssignees.assignees.nodes"
                :can-set-work-item-metadata="canAssignUnassignUser"
                :can-summarize-comments="canSummarizeComments"
                :can-create-note="canCreateNote"
                :is-discussion-locked="isDiscussionLocked"
                :is-work-item-confidential="workItem.confidential"
                :new-comment-template-paths="workItem.commentTemplatesPaths"
                class="gl-pt-5"
                :use-h2="!isModalOrDrawer"
                :small-header-style="isModal"
                :parent-id="parentWorkItemId"
                :hide-fullscreen-markdown-button="isDrawer"
                @error="updateError = $event"
                @openReportAbuse="openReportAbuseModal"
                @startEditing="isAddingNotes = true"
                @stopEditing="isAddingNotes = false"
                @focus="isAddingNotes = true"
                @blur="isAddingNotes = false"
              />
            </div>
          </div>
        </section>
      </section>
      <work-item-drawer
        v-if="contextualViewEnabled && !isDrawer"
        :active-item="activeChildItem"
        :open="isItemSelected"
        :issuable-type="activeChildItemType"
        click-outside-exclude-selector=".issuable-list"
        @close="activeChildItem = null"
        @workItemDeleted="deleteChildItem"
      />
      <work-item-abuse-modal
        v-if="isReportModalOpen"
        :show-modal="isReportModalOpen"
        :reported-user-id="reportedUserId"
        :reported-from-url="reportedUrl"
        @close-modal="toggleReportAbuseModal(false)"
      />
    </div>
  </work-item-metadata-provider>
</template>
