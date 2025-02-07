<script>
import {
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlDropdownDivider,
  GlLoadingIcon,
  GlModal,
  GlModalDirective,
  GlTooltipDirective,
  GlToggle,
} from '@gitlab/ui';

import * as Sentry from '~/sentry/sentry_browser_wrapper';

import { __, s__ } from '~/locale';
import Tracking from '~/tracking';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import toast from '~/vue_shared/plugins/global_toast';
import { isLoggedIn } from '~/lib/utils/common_utils';

import WorkItemChangeTypeModal from 'ee_else_ce/work_items/components/work_item_change_type_modal.vue';
import {
  sprintfWorkItem,
  BASE_ALLOWED_CREATE_TYPES,
  I18N_WORK_ITEM_DELETE,
  I18N_WORK_ITEM_ARE_YOU_SURE_DELETE,
  I18N_WORK_ITEM_ARE_YOU_SURE_DELETE_HIERARCHY,
  TEST_ID_CONFIDENTIALITY_TOGGLE_ACTION,
  TEST_ID_NOTIFICATIONS_TOGGLE_FORM,
  TEST_ID_DELETE_ACTION,
  TEST_ID_PROMOTE_ACTION,
  TEST_ID_CHANGE_TYPE_ACTION,
  TEST_ID_COPY_CREATE_NOTE_EMAIL_ACTION,
  TEST_ID_COPY_REFERENCE_ACTION,
  TEST_ID_TOGGLE_ACTION,
  I18N_WORK_ITEM_ERROR_CONVERTING,
  WORK_ITEM_TYPE_VALUE_KEY_RESULT,
  WORK_ITEM_TYPE_VALUE_OBJECTIVE,
  I18N_WORK_ITEM_COPY_CREATE_NOTE_EMAIL,
  I18N_WORK_ITEM_ERROR_COPY_REFERENCE,
  I18N_WORK_ITEM_ERROR_COPY_EMAIL,
  I18N_WORK_ITEM_NEW_RELATED_ITEM,
  TEST_ID_LOCK_ACTION,
  TEST_ID_REPORT_ABUSE,
  TEST_ID_NEW_RELATED_WORK_ITEM,
  WORK_ITEM_TYPE_ENUM_EPIC,
  WORK_ITEM_TYPE_VALUE_EPIC,
  WORK_ITEM_TYPE_VALUE_MAP,
} from '../constants';
import updateWorkItemMutation from '../graphql/update_work_item.mutation.graphql';
import updateWorkItemNotificationsMutation from '../graphql/update_work_item_notifications.mutation.graphql';
import convertWorkItemMutation from '../graphql/work_item_convert.mutation.graphql';
import namespaceWorkItemTypesQuery from '../graphql/namespace_work_item_types.query.graphql';
import WorkItemStateToggle from './work_item_state_toggle.vue';
import CreateWorkItemModal from './create_work_item_modal.vue';

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
    GlLoadingIcon,
    GlModal,
    GlToggle,
    WorkItemStateToggle,
    CreateWorkItemModal,
    WorkItemChangeTypeModal,
  },
  directives: {
    GlModal: GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagMixin(), Tracking.mixin({ label: 'actions_menu' })],
  isLoggedIn: isLoggedIn(),
  notificationsToggleFormTestId: TEST_ID_NOTIFICATIONS_TOGGLE_FORM,
  confidentialityTestId: TEST_ID_CONFIDENTIALITY_TOGGLE_ACTION,
  copyReferenceTestId: TEST_ID_COPY_REFERENCE_ACTION,
  copyCreateNoteEmailTestId: TEST_ID_COPY_CREATE_NOTE_EMAIL_ACTION,
  deleteActionTestId: TEST_ID_DELETE_ACTION,
  promoteActionTestId: TEST_ID_PROMOTE_ACTION,
  changeTypeTestId: TEST_ID_CHANGE_TYPE_ACTION,
  lockDiscussionTestId: TEST_ID_LOCK_ACTION,
  stateToggleTestId: TEST_ID_TOGGLE_ACTION,
  reportAbuseActionTestId: TEST_ID_REPORT_ABUSE,
  newRelatedItemTestId: TEST_ID_NEW_RELATED_WORK_ITEM,
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
    workItemTypeId: {
      type: String,
      required: false,
      default: null,
    },
    canUpdate: {
      type: Boolean,
      required: false,
      default: false,
    },
    canDelete: {
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
  },
  data() {
    return {
      isLockDiscussionUpdating: false,
      isDropdownVisible: false,
      isCreateWorkItemModalVisible: false,
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
        return !this.canUpdate || this.workItemType !== WORK_ITEM_TYPE_VALUE_KEY_RESULT;
      },
    },
  },
  computed: {
    i18n() {
      return {
        deleteWorkItem: sprintfWorkItem(I18N_WORK_ITEM_DELETE, this.workItemType),
        convertError: sprintfWorkItem(I18N_WORK_ITEM_ERROR_CONVERTING, this.workItemType),
        copyCreateNoteEmail: sprintfWorkItem(
          I18N_WORK_ITEM_COPY_CREATE_NOTE_EMAIL,
          this.workItemType,
        ),
        copyReferenceError: sprintfWorkItem(I18N_WORK_ITEM_ERROR_COPY_REFERENCE, this.workItemType),
        copyCreateNoteEmailError: sprintfWorkItem(
          I18N_WORK_ITEM_ERROR_COPY_EMAIL,
          this.workItemType,
        ),
      };
    },
    newRelatedItemLabel() {
      return this.workItemType === WORK_ITEM_TYPE_VALUE_EPIC
        ? sprintfWorkItem(I18N_WORK_ITEM_NEW_RELATED_ITEM, this.workItemType)
        : s__('WorkItem|New related item');
    },
    areYouSureDeleteMessage() {
      return this.hasChildren
        ? sprintfWorkItem(I18N_WORK_ITEM_ARE_YOU_SURE_DELETE_HIERARCHY, this.workItemType)
        : sprintfWorkItem(I18N_WORK_ITEM_ARE_YOU_SURE_DELETE, this.workItemType);
    },
    canLockWorkItem() {
      return this.canUpdate;
    },
    canPromoteToObjective() {
      return this.canUpdate && this.workItemType === WORK_ITEM_TYPE_VALUE_KEY_RESULT;
    },
    confidentialItem() {
      return {
        text: this.isConfidential
          ? this.$options.i18n.disableConfidentiality
          : this.$options.i18n.enableConfidentiality,
        extraAttrs: {
          disabled: this.isParentConfidential,
        },
      };
    },
    confidentialTooltip() {
      return this.isParentConfidential ? this.$options.i18n.confidentialParentTooltip : '';
    },
    lockDiscussionText() {
      return this.isDiscussionLocked ? __('Unlock discussion') : __('Lock discussion');
    },
    objectiveWorkItemTypeId() {
      return this.workItemTypes.find((type) => type.name === WORK_ITEM_TYPE_VALUE_OBJECTIVE).id;
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
      return this.workItemType === WORK_ITEM_TYPE_VALUE_EPIC;
    },
    confidentialityToggledText() {
      return this.isConfidential
        ? this.$options.i18n.confidentialityDisabled
        : this.$options.i18n.confidentialityEnabled;
    },
    showChangeType() {
      return !this.isEpic && this.canUpdate;
    },
    allowedWorkItemTypes() {
      if (this.isGroup) {
        return [];
      }

      if (this.glFeatures.okrsMvc && this.hasOkrsFeature) {
        return BASE_ALLOWED_CREATE_TYPES.concat(
          WORK_ITEM_TYPE_VALUE_KEY_RESULT,
          WORK_ITEM_TYPE_VALUE_OBJECTIVE,
        );
      }

      return BASE_ALLOWED_CREATE_TYPES;
    },
    workItemTypeNameEnum() {
      return WORK_ITEM_TYPE_VALUE_MAP[this.workItemType];
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
          :data-testid="$options.notificationsToggleFormTestId"
        >
          <template #list-item>
            <gl-toggle
              :value="subscribedToNotifications"
              :label="$options.i18n.notifications"
              label-position="left"
              class="work-item-dropdown-toggle gl-justify-between"
              @change="toggleNotifications($event)"
            />
          </template>
        </gl-disclosure-dropdown-item>
        <gl-dropdown-divider />
      </template>

      <work-item-state-toggle
        v-if="canUpdate"
        :data-testid="$options.stateToggleTestId"
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
        :data-testid="$options.newRelatedItemTestId"
        @action="isCreateWorkItemModalVisible = true"
      >
        <template #list-item>{{ newRelatedItemLabel }}</template>
      </gl-disclosure-dropdown-item>

      <gl-disclosure-dropdown-item
        v-if="canPromoteToObjective"
        :data-testid="$options.promoteActionTestId"
        @action="promoteToObjective"
      >
        <template #list-item>{{ __('Promote to objective') }}</template>
      </gl-disclosure-dropdown-item>

      <gl-disclosure-dropdown-item
        v-if="showChangeType"
        :data-testid="$options.changeTypeTestId"
        @action="showChangeTypeModal"
      >
        <template #list-item>{{ $options.i18n.changeWorkItemType }}</template>
      </gl-disclosure-dropdown-item>

      <gl-disclosure-dropdown-item
        v-if="canLockWorkItem"
        :data-testid="$options.lockDiscussionTestId"
        @action="toggleDiscussionLock"
      >
        <template #list-item>
          <gl-loading-icon v-if="isLockDiscussionUpdating" class="gl-mr-1" inline />
          {{ lockDiscussionText }}
        </template>
      </gl-disclosure-dropdown-item>

      <gl-disclosure-dropdown-item
        v-if="canUpdate"
        v-gl-tooltip.left.viewport.d0="confidentialTooltip"
        :item="confidentialItem"
        :data-testid="$options.confidentialityTestId"
        @action="handleToggleWorkItemConfidentiality"
      />

      <gl-disclosure-dropdown-item
        :data-testid="$options.copyReferenceTestId"
        :data-clipboard-text="workItemReference"
        class="shortcut-copy-reference"
        @action="copyToClipboard(workItemReference, $options.i18n.referenceCopied)"
      >
        <template #list-item>{{ $options.i18n.copyReference }}</template>
      </gl-disclosure-dropdown-item>

      <gl-disclosure-dropdown-item
        v-if="$options.isLoggedIn && workItemCreateNoteEmail"
        :data-testid="$options.copyCreateNoteEmailTestId"
        :data-clipboard-text="workItemCreateNoteEmail"
        @action="copyToClipboard(workItemCreateNoteEmail, $options.i18n.emailAddressCopied)"
      >
        <template #list-item>{{ i18n.copyCreateNoteEmail }}</template>
      </gl-disclosure-dropdown-item>

      <gl-dropdown-divider />

      <gl-disclosure-dropdown-item
        v-if="!isAuthor"
        :data-testid="$options.reportAbuseActionTestId"
        @action="handleToggleReportAbuseModal"
      >
        <template #list-item>{{ $options.i18n.reportAbuse }}</template>
      </gl-disclosure-dropdown-item>

      <gl-disclosure-dropdown-item
        v-if="glFeatures.workItemsBeta && canReportSpam"
        :item="submitAsSpamItem"
        data-testid="submit-as-spam-item"
      />

      <template v-if="canDelete">
        <gl-disclosure-dropdown-item
          :data-testid="$options.deleteActionTestId"
          variant="danger"
          @action="handleDelete"
        >
          <template #list-item>
            <span class="gl-text-danger">{{ i18n.deleteWorkItem }}</span>
          </template>
        </gl-disclosure-dropdown-item>
      </template>
    </gl-disclosure-dropdown>

    <gl-modal
      ref="modal"
      modal-id="work-item-confirm-delete"
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
  </div>
</template>
