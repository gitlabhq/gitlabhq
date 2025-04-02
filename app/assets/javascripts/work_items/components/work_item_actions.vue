<script>
import {
  GlDisclosureDropdown,
  GlDisclosureDropdownGroup,
  GlDisclosureDropdownItem,
  GlDropdownDivider,
  GlIcon,
  GlLoadingIcon,
  GlModal,
  GlModalDirective,
  GlTooltipDirective,
  GlToggle,
} from '@gitlab/ui';

import * as Sentry from '~/sentry/sentry_browser_wrapper';

import { __, s__ } from '~/locale';
import { getModifierKey } from '~/constants';
import Tracking from '~/tracking';
import { shouldDisableShortcuts } from '~/behaviors/shortcuts/shortcuts_toggle';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import toast from '~/vue_shared/plugins/global_toast';
import { isLoggedIn } from '~/lib/utils/common_utils';

import WorkItemChangeTypeModal from 'ee_else_ce/work_items/components/work_item_change_type_modal.vue';
import {
  sprintfWorkItem,
  BASE_ALLOWED_CREATE_TYPES,
  WORK_ITEM_TYPE_NAME_KEY_RESULT,
  WORK_ITEM_TYPE_NAME_OBJECTIVE,
  WORK_ITEM_TYPE_ENUM_EPIC,
  WORK_ITEM_TYPE_NAME_EPIC,
  WORK_ITEM_TYPE_VALUE_MAP,
  WORK_ITEM_TYPE_NAME_ISSUE,
} from '../constants';
import updateWorkItemMutation from '../graphql/update_work_item.mutation.graphql';
import updateWorkItemNotificationsMutation from '../graphql/update_work_item_notifications.mutation.graphql';
import convertWorkItemMutation from '../graphql/work_item_convert.mutation.graphql';
import namespaceWorkItemTypesQuery from '../graphql/namespace_work_item_types.query.graphql';
import WorkItemStateToggle from './work_item_state_toggle.vue';
import CreateWorkItemModal from './create_work_item_modal.vue';
import MoveWorkItemModal from './move_work_item_modal.vue';

export default {
  i18n: {
    enableConfidentiality: s__('WorkItem|Turn on confidentiality'),
    disableConfidentiality: s__('WorkItem|Turn off confidentiality'),
    confidentialityEnabled: s__('WorkItem|Confidentiality turned on.'),
    confidentialityDisabled: s__('WorkItem|Confidentiality turned off.'),
    confidentialParentTooltip: s__(
      'WorkItem|Child items of a confidential parent must be confidential. Turn off confidentiality on the parent item first.',
    ),
    notifications: s__('WorkItem|Notifications'),
    notificationOn: s__('WorkItem|Notifications turned on.'),
    notificationOff: s__('WorkItem|Notifications turned off.'),
    copyReference: __('Copy reference'),
    referenceCopied: __('Reference copied'),
    emailAddressCopied: __('Email address copied'),
    moreActions: __('More actions'),
    reportAbuse: __('Report abuse'),
    changeWorkItemType: s__('WorkItem|Change type'),
  },
  WORK_ITEM_TYPE_ENUM_EPIC,
  components: {
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlDropdownDivider,
    GlDisclosureDropdownGroup,
    GlIcon,
    GlLoadingIcon,
    GlModal,
    GlToggle,
    WorkItemStateToggle,
    CreateWorkItemModal,
    WorkItemChangeTypeModal,
    MoveWorkItemModal,
  },
  directives: {
    GlModal: GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagMixin(), Tracking.mixin({ label: 'actions_menu' })],
  isLoggedIn: isLoggedIn(),
  inject: ['hasOkrsFeature'],
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    workItemState: {
      type: String,
      required: false,
      default: null,
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
    workItemType: {
      type: String,
      required: false,
      default: null,
    },
    projectId: {
      type: String,
      required: false,
      default: null,
    },
    canUpdate: {
      type: Boolean,
      required: false,
      default: false,
    },
    canUpdateMetadata: {
      type: Boolean,
      required: false,
      default: false,
    },
    canDelete: {
      type: Boolean,
      required: false,
      default: false,
    },
    canMove: {
      type: Boolean,
      required: false,
      default: false,
    },
    canReportSpam: {
      type: Boolean,
      required: false,
      default: false,
    },
    isConfidential: {
      type: Boolean,
      required: false,
      default: false,
    },
    isDiscussionLocked: {
      type: Boolean,
      required: false,
      default: false,
    },
    isParentConfidential: {
      type: Boolean,
      required: false,
      default: false,
    },
    subscribedToNotifications: {
      type: Boolean,
      required: false,
      default: false,
    },
    workItemReference: {
      type: String,
      required: false,
      default: null,
    },
    workItemWebUrl: {
      type: String,
      required: false,
      default: null,
    },
    workItemCreateNoteEmail: {
      type: String,
      required: false,
      default: null,
    },
    isModal: {
      type: Boolean,
      required: false,
      default: false,
    },
    hideSubscribe: {
      type: Boolean,
      required: false,
      default: false,
    },
    hasChildren: {
      type: Boolean,
      required: false,
      default: false,
    },
    hasParent: {
      type: Boolean,
      required: false,
      default: false,
    },
    parentId: {
      type: String,
      required: false,
      default: null,
    },
    workItemAuthorId: {
      type: Number,
      required: false,
      default: 0,
    },
    canCreateRelatedItem: {
      type: Boolean,
      required: false,
      default: false,
    },
    isGroup: {
      type: Boolean,
      required: true,
    },
    widgets: {
      type: Array,
      required: false,
      default: () => [],
    },
    allowedChildTypes: {
      type: Array,
      required: false,
      default: () => [],
    },
    namespaceFullName: {
      type: String,
      required: false,
      default: '',
    },
    showSidebar: {
      type: Boolean,
      required: true,
    },
    truncationEnabled: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      isLockDiscussionUpdating: false,
      isDropdownVisible: false,
      isCreateWorkItemModalVisible: false,
      isMoveWorkItemModalVisible: false,
      workItemTypes: [],
    };
  },
  apollo: {
    workItemTypes: {
      query: namespaceWorkItemTypesQuery,
      variables() {
        return {
          fullPath: this.fullPath,
        };
      },
      update(data) {
        return data.workspace?.workItemTypes?.nodes;
      },
      skip() {
        return !this.canUpdateMetadata || this.workItemType !== WORK_ITEM_TYPE_NAME_KEY_RESULT;
      },
    },
  },
  computed: {
    i18n() {
      return {
        deleteWorkItem: sprintfWorkItem(s__('WorkItem|Delete %{workItemType}'), this.workItemType),
        convertError: sprintfWorkItem(
          s__(
            'WorkItem|Something went wrong while promoting the %{workItemType}. Please try again.',
          ),
          this.workItemType,
        ),
        copyCreateNoteEmail: sprintfWorkItem(
          s__('WorkItem|Copy %{workItemType} email address'),
          this.workItemType,
        ),
        copyReferenceError: sprintfWorkItem(
          s__(
            'WorkItem|Something went wrong while copying the %{workItemType} reference. Please try again.',
          ),
          this.workItemType,
        ),
        copyCreateNoteEmailError: sprintfWorkItem(
          s__(
            'WorkItem|Something went wrong while copying the %{workItemType} email address. Please try again.',
          ),
          this.workItemType,
        ),
      };
    },
    newRelatedItemLabel() {
      return this.workItemType === WORK_ITEM_TYPE_NAME_EPIC
        ? sprintfWorkItem(s__('WorkItem|New related %{workItemType}'), this.workItemType)
        : s__('WorkItem|New related item');
    },
    areYouSureDeleteMessage() {
      const message = this.hasChildren
        ? s__(
            'WorkItem|Delete this %{workItemType} and release all child items? This action cannot be reversed.',
          )
        : s__(
            'WorkItem|Are you sure you want to delete the %{workItemType}? This action cannot be reversed.',
          );
      return sprintfWorkItem(message, this.workItemType);
    },
    canPromoteToObjective() {
      return this.canUpdateMetadata && this.workItemType === WORK_ITEM_TYPE_NAME_KEY_RESULT;
    },
    confidentialItem() {
      return {
        text: this.confidentialItemText,
        extraAttrs: { disabled: this.isParentConfidential },
      };
    },
    confidentialItemText() {
      return this.isConfidential
        ? this.$options.i18n.disableConfidentiality
        : this.$options.i18n.enableConfidentiality;
    },
    confidentialItemIcon() {
      return this.isConfidential ? 'eye' : 'eye-slash';
    },
    confidentialItemIconVariant() {
      return this.isParentConfidential ? 'current' : 'subtle';
    },
    confidentialTooltip() {
      return this.isParentConfidential ? this.$options.i18n.confidentialParentTooltip : '';
    },
    lockDiscussionText() {
      return this.isDiscussionLocked ? __('Unlock discussion') : __('Lock discussion');
    },
    lockDiscussionIcon() {
      return this.isDiscussionLocked ? 'lock-open' : 'lock';
    },
    objectiveWorkItemTypeId() {
      return this.workItemTypes.find((type) => type.name === WORK_ITEM_TYPE_NAME_OBJECTIVE).id;
    },
    showDropdownTooltip() {
      return !this.isDropdownVisible ? this.$options.i18n.moreActions : '';
    },
    submitAsSpamItem() {
      const href = this.workItemWebUrl.replaceAll('work_items', 'issues').concat('/mark_as_spam');
      return { text: __('Submit as spam'), href };
    },
    isAuthor() {
      return this.workItemAuthorId === window.gon.current_user_id;
    },
    relatedItemData() {
      return {
        id: this.workItemId,
        reference: this.workItemReference,
        type: this.workItemType,
        webUrl: this.workItemWebUrl,
      };
    },
    isEpic() {
      return this.workItemType === WORK_ITEM_TYPE_NAME_EPIC;
    },
    confidentialityToggledText() {
      return this.isConfidential
        ? this.$options.i18n.confidentialityDisabled
        : this.$options.i18n.confidentialityEnabled;
    },
    showChangeType() {
      return !this.isEpic && this.canUpdateMetadata;
    },
    allowedWorkItemTypes() {
      if (this.isGroup) {
        return [];
      }

      if (this.glFeatures.okrsMvc && this.hasOkrsFeature) {
        return BASE_ALLOWED_CREATE_TYPES.concat(
          WORK_ITEM_TYPE_NAME_KEY_RESULT,
          WORK_ITEM_TYPE_NAME_OBJECTIVE,
        );
      }

      return BASE_ALLOWED_CREATE_TYPES;
    },
    workItemTypeNameEnum() {
      return WORK_ITEM_TYPE_VALUE_MAP[this.workItemType];
    },
    showMoveButton() {
      return this.workItemType === WORK_ITEM_TYPE_NAME_ISSUE && this.canMove;
    },
    toggleSidebarLabel() {
      return this.showSidebar ? s__('WorkItem|Hide sidebar') : s__('WorkItem|Show sidebar');
    },
    toggleSidebarKeys() {
      const modifierKey = getModifierKey();
      return shouldDisableShortcuts() ? null : `${modifierKey}/`;
    },
  },
  methods: {
    copyToClipboard(text, message) {
      if (this.isModal) {
        navigator.clipboard.writeText(text);
      }
      toast(message);
      this.closeDropdown();
    },
    handleToggleWorkItemConfidentiality() {
      this.track('click_toggle_work_item_confidentiality');
      this.$emit('toggleWorkItemConfidentiality', !this.isConfidential);
      toast(this.confidentialityToggledText);
      this.closeDropdown();
    },
    handleDelete() {
      this.$refs.modal.show();
      this.closeDropdown();
    },
    handleDeleteWorkItem() {
      this.track('click_delete_work_item');
      this.$emit('deleteWorkItem');
    },
    handleCancelDeleteWorkItem({ trigger }) {
      if (trigger !== 'ok') {
        this.track('cancel_delete_work_item');
      }
    },
    toggleNotifications(subscribed) {
      this.$apollo
        .mutate({
          mutation: updateWorkItemNotificationsMutation,
          variables: {
            input: {
              id: this.workItemId,
              subscribed,
            },
          },
        })
        .then(({ data }) => {
          const { errors } = data.workItemSubscribe;
          if (errors?.length) {
            throw new Error(errors[0]);
          }

          toast(
            subscribed ? this.$options.i18n.notificationOn : this.$options.i18n.notificationOff,
          );
        })
        .catch((error) => {
          this.$emit('error', error.message);
          Sentry.captureException(error);
        });
    },
    throwConvertError() {
      this.$emit('error', this.i18n.convertError);
    },
    closeDropdown() {
      this.$refs.workItemsMoreActions.close();
    },
    toggleDiscussionLock() {
      this.isLockDiscussionUpdating = true;

      this.$apollo
        .mutate({
          mutation: updateWorkItemMutation,
          variables: {
            input: {
              id: this.workItemId,
              notesWidget: {
                discussionLocked: !this.isDiscussionLocked,
              },
            },
          },
        })
        .then(({ data }) => {
          const { errors } = data.workItemUpdate;
          if (errors?.length) {
            throw new Error(errors);
          }

          toast(this.isDiscussionLocked ? __('Discussion locked.') : __('Discussion unlocked.'));
        })
        .catch((error) => {
          this.$emit('error', error.message);
          Sentry.captureException(error);
        })
        .finally(() => {
          this.isLockDiscussionUpdating = false;
        });
    },
    async promoteToObjective() {
      try {
        const {
          data: {
            workItemConvert: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: convertWorkItemMutation,
          variables: {
            input: {
              id: this.workItemId,
              workItemTypeId: this.objectiveWorkItemTypeId,
            },
          },
        });
        if (errors.length > 0) {
          this.throwConvertError();
          return;
        }
        this.$toast.show(s__('WorkItem|Promoted to objective.'));
        this.track('promote_kr_to_objective');
        this.$emit('promotedToObjective');
      } catch (error) {
        this.throwConvertError();
        Sentry.captureException(error);
      } finally {
        this.closeDropdown();
      }
    },
    showDropdown() {
      this.isDropdownVisible = true;
    },
    hideDropdown() {
      this.isDropdownVisible = false;
    },
    emitStateToggleError(error) {
      this.$emit('error', error);
    },
    handleToggleReportAbuseModal() {
      this.$emit('toggleReportAbuseModal', true);
      this.closeDropdown();
    },
    showChangeTypeModal() {
      this.$refs.workItemsChangeTypeModal.show();
    },
  },
};
</script>

<template>
  <div>
    <gl-disclosure-dropdown
      ref="workItemsMoreActions"
      v-gl-tooltip="showDropdownTooltip"
      icon="ellipsis_v"
      data-testid="work-item-actions-dropdown"
      text-sr-only
      :toggle-text="$options.i18n.moreActions"
      category="tertiary"
      :auto-close="false"
      no-caret
      right
      @shown="showDropdown"
      @hidden="hideDropdown"
    >
      <template v-if="$options.isLoggedIn && !hideSubscribe">
        <gl-disclosure-dropdown-item
          class="gl-flex gl-w-full gl-justify-end"
          data-testid="notifications-toggle-form"
        >
          <template #list-item>
            <gl-toggle
              :value="subscribedToNotifications"
              label-position="left"
              data-testid="notifications-toggle"
              class="work-item-dropdown-toggle gl-justify-between"
              @change="toggleNotifications($event)"
            >
              <template #label>
                <span :title="$options.i18n.notifications" class="gl-flex gl-gap-3 gl-pt-1">
                  <gl-icon name="notifications" variant="subtle" />
                  <span class="gl-max-w-[154px] gl-truncate">{{
                    $options.i18n.notifications
                  }}</span>
                </span>
              </template>
            </gl-toggle>
          </template>
        </gl-disclosure-dropdown-item>
        <gl-dropdown-divider />
      </template>

      <work-item-state-toggle
        v-if="canUpdate"
        data-testid="state-toggle-action"
        :work-item-id="workItemId"
        :work-item-iid="workItemIid"
        :work-item-state="workItemState"
        :work-item-type="workItemType"
        :full-path="fullPath"
        :parent-id="parentId"
        show-as-dropdown-item
        @error="emitStateToggleError"
        @workItemStateUpdated="$emit('workItemStateUpdated')"
      />

      <gl-disclosure-dropdown-item
        v-if="canCreateRelatedItem && canUpdate"
        data-testid="new-related-work-item"
        @action="isCreateWorkItemModalVisible = true"
      >
        <template #list-item>
          <gl-icon name="plus" class="gl-mr-2" variant="subtle" />
          {{ newRelatedItemLabel }}
        </template>
      </gl-disclosure-dropdown-item>

      <gl-disclosure-dropdown-item
        v-if="canPromoteToObjective"
        data-testid="promote-action"
        @action="promoteToObjective"
      >
        <template #list-item>
          <gl-icon name="level-up" class="gl-mr-2" variant="subtle" />
          {{ __('Promote to objective') }}
        </template>
      </gl-disclosure-dropdown-item>

      <gl-disclosure-dropdown-item
        v-if="showChangeType"
        data-testid="change-type-action"
        @action="showChangeTypeModal"
      >
        <template #list-item>
          <gl-icon name="issue-type-issue" class="gl-mr-2" variant="subtle" />
          {{ $options.i18n.changeWorkItemType }}
        </template>
      </gl-disclosure-dropdown-item>

      <gl-disclosure-dropdown-item
        v-if="showMoveButton"
        data-testid="move-action"
        @action="isMoveWorkItemModalVisible = true"
      >
        <template #list-item>
          <gl-icon name="long-arrow" class="gl-mr-2" variant="subtle" />
          {{ __('Move') }}
        </template>
      </gl-disclosure-dropdown-item>

      <gl-disclosure-dropdown-item
        v-if="canUpdateMetadata"
        data-testid="lock-action"
        @action="toggleDiscussionLock"
      >
        <template #list-item>
          <gl-loading-icon v-if="isLockDiscussionUpdating" class="gl-mr-2" inline />
          <gl-icon :name="lockDiscussionIcon" class="gl-mr-2" variant="subtle" />
          {{ lockDiscussionText }}
        </template>
      </gl-disclosure-dropdown-item>

      <gl-disclosure-dropdown-item
        v-if="canUpdateMetadata"
        v-gl-tooltip.left.viewport.d0="confidentialTooltip"
        :item="confidentialItem"
        data-testid="confidentiality-toggle-action"
        @action="handleToggleWorkItemConfidentiality"
      >
        <template #list-item>
          <gl-icon
            :name="confidentialItemIcon"
            class="gl-mr-2"
            :variant="confidentialItemIconVariant"
          />
          {{ confidentialItemText }}
        </template>
      </gl-disclosure-dropdown-item>

      <gl-disclosure-dropdown-item
        data-testid="copy-reference-action"
        :data-clipboard-text="workItemReference"
        class="shortcut-copy-reference"
        @action="copyToClipboard(workItemReference, $options.i18n.referenceCopied)"
      >
        <template #list-item>
          <gl-icon name="copy-to-clipboard" class="gl-mr-2" variant="subtle" />
          {{ $options.i18n.copyReference }}
        </template>
      </gl-disclosure-dropdown-item>

      <gl-disclosure-dropdown-item
        v-if="$options.isLoggedIn && workItemCreateNoteEmail"
        data-testid="copy-create-note-email-action"
        :data-clipboard-text="workItemCreateNoteEmail"
        @action="copyToClipboard(workItemCreateNoteEmail, $options.i18n.emailAddressCopied)"
      >
        <template #list-item>
          <gl-icon name="copy-to-clipboard" class="gl-mr-2" variant="subtle" />
          {{ i18n.copyCreateNoteEmail }}
        </template>
      </gl-disclosure-dropdown-item>

      <gl-dropdown-divider />

      <gl-disclosure-dropdown-item
        v-if="!isAuthor"
        data-testid="report-abuse-action"
        @action="handleToggleReportAbuseModal"
      >
        <template #list-item>
          <gl-icon name="review-warning" class="gl-mr-2" variant="subtle" />
          {{ $options.i18n.reportAbuse }}
        </template>
      </gl-disclosure-dropdown-item>

      <gl-disclosure-dropdown-item
        v-if="glFeatures.workItemsBeta && canReportSpam"
        :item="submitAsSpamItem"
        data-testid="submit-as-spam-item"
      />

      <template v-if="canDelete">
        <gl-disclosure-dropdown-item
          data-testid="delete-action"
          variant="danger"
          @action="handleDelete"
        >
          <template #list-item>
            <span>
              <gl-icon name="remove" class="gl-mr-2" variant="current" />
              {{ i18n.deleteWorkItem }}
            </span>
          </template>
        </gl-disclosure-dropdown-item>
      </template>

      <gl-disclosure-dropdown-group bordered>
        <template #group-label>
          {{ __('View options') }}
          <gl-icon
            v-gl-tooltip
            name="information-o"
            class="gl-ml-2"
            variant="link"
            :title="s__('WorkItem|Change appearance for all issues, epics, and tasks')"
          />
        </template>
        <gl-disclosure-dropdown-item
          class="gl-flex gl-w-full gl-justify-end"
          data-testid="truncation-toggle-action"
          @action="$emit('toggleTruncationEnabled')"
        >
          <template #list-item>
            <gl-toggle
              :value="truncationEnabled"
              label-position="left"
              class="work-item-dropdown-toggle gl-justify-between"
            >
              <template #label>
                <span
                  :title="s__('WorkItem|Truncate descriptions')"
                  class="gl-flex gl-gap-3 gl-pt-1"
                >
                  <gl-icon name="text-description" variant="subtle" />
                  <span class="gl-max-w-[154px] gl-truncate">{{
                    s__('WorkItem|Truncate descriptions')
                  }}</span>
                </span>
              </template>
            </gl-toggle>
          </template>
        </gl-disclosure-dropdown-item>
        <gl-disclosure-dropdown-item
          data-testid="sidebar-toggle-action"
          class="work-item-container-xs-hidden js-sidebar-toggle-action gl-hidden md:gl-block"
          @action="$emit('toggleSidebar')"
        >
          <template #list-item>
            <div class="gl-flex gl-items-center gl-justify-between">
              <span>
                <gl-icon name="sidebar-right" class="gl-mr-2" variant="subtle" />
                {{ toggleSidebarLabel }}
              </span>
              <kbd v-if="toggleSidebarKeys" class="flat">{{ toggleSidebarKeys }}</kbd>
            </div>
          </template>
        </gl-disclosure-dropdown-item>
      </gl-disclosure-dropdown-group>
    </gl-disclosure-dropdown>

    <gl-modal
      ref="modal"
      modal-id="work-item-confirm-delete"
      data-testid="work-item-confirm-delete"
      :title="i18n.deleteWorkItem"
      :ok-title="i18n.deleteWorkItem"
      ok-variant="danger"
      @ok="handleDeleteWorkItem"
      @hide="handleCancelDeleteWorkItem"
    >
      {{ areYouSureDeleteMessage }}
    </gl-modal>

    <create-work-item-modal
      :allowed-work-item-types="allowedWorkItemTypes"
      :always-show-work-item-type-select="!isGroup"
      :visible="isCreateWorkItemModalVisible"
      :related-item="relatedItemData"
      :work-item-type-name="workItemTypeNameEnum"
      :show-project-selector="!isEpic"
      :is-group="isGroup"
      hide-button
      @workItemCreated="$emit('workItemCreated')"
      @hideModal="isCreateWorkItemModalVisible = false"
    />
    <work-item-change-type-modal
      v-if="showChangeType"
      ref="workItemsChangeTypeModal"
      :work-item-id="workItemId"
      :work-item-iid="workItemIid"
      :work-item-type="workItemType"
      :full-path="fullPath"
      :has-children="hasChildren"
      :has-parent="hasParent"
      :widgets="widgets"
      :allowed-child-types="allowedChildTypes"
      :namespace-full-name="namespaceFullName"
      @workItemTypeChanged="$emit('workItemTypeChanged')"
      @error="$emit('error', $event)"
    />
    <move-work-item-modal
      v-if="projectId"
      :visible="isMoveWorkItemModalVisible"
      :work-item-id="workItemId"
      :work-item-iid="workItemIid"
      :full-path="fullPath"
      :project-id="projectId"
      @hideModal="isMoveWorkItemModalVisible = false"
    />
  </div>
</template>
