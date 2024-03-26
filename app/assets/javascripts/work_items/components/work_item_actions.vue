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

import {
  sprintfWorkItem,
  I18N_WORK_ITEM_DELETE,
  I18N_WORK_ITEM_ARE_YOU_SURE_DELETE,
  TEST_ID_CONFIDENTIALITY_TOGGLE_ACTION,
  TEST_ID_NOTIFICATIONS_TOGGLE_FORM,
  TEST_ID_DELETE_ACTION,
  TEST_ID_PROMOTE_ACTION,
  TEST_ID_COPY_CREATE_NOTE_EMAIL_ACTION,
  TEST_ID_COPY_REFERENCE_ACTION,
  TEST_ID_TOGGLE_ACTION,
  I18N_WORK_ITEM_ERROR_CONVERTING,
  WORK_ITEM_TYPE_VALUE_KEY_RESULT,
  WORK_ITEM_TYPE_VALUE_OBJECTIVE,
  I18N_WORK_ITEM_COPY_CREATE_NOTE_EMAIL,
  I18N_WORK_ITEM_ERROR_COPY_REFERENCE,
  I18N_WORK_ITEM_ERROR_COPY_EMAIL,
  TEST_ID_LOCK_ACTION,
} from '../constants';
import updateWorkItemMutation from '../graphql/update_work_item.mutation.graphql';
import updateWorkItemNotificationsMutation from '../graphql/update_work_item_notifications.mutation.graphql';
import convertWorkItemMutation from '../graphql/work_item_convert.mutation.graphql';
import projectWorkItemTypesQuery from '../graphql/project_work_item_types.query.graphql';
import WorkItemStateToggle from './work_item_state_toggle.vue';

export default {
  i18n: {
    enableConfidentiality: s__('WorkItem|Turn on confidentiality'),
    disableConfidentiality: s__('WorkItem|Turn off confidentiality'),
    notifications: s__('WorkItem|Notifications'),
    notificationOn: s__('WorkItem|Notifications turned on.'),
    notificationOff: s__('WorkItem|Notifications turned off.'),
    copyReference: __('Copy reference'),
    referenceCopied: __('Reference copied'),
    emailAddressCopied: __('Email address copied'),
    moreActions: __('More actions'),
  },
  components: {
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlDropdownDivider,
    GlLoadingIcon,
    GlModal,
    GlToggle,
    WorkItemStateToggle,
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
  lockDiscussionTestId: TEST_ID_LOCK_ACTION,
  stateToggleTestId: TEST_ID_TOGGLE_ACTION,
  inject: ['isGroup'],
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    workItemState: {
      type: String,
      required: true,
    },
    workItemId: {
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
  },
  data() {
    return {
      isLockDiscussionUpdating: false,
      isDropdownVisible: false,
    };
  },
  apollo: {
    workItemTypes: {
      query: projectWorkItemTypesQuery,
      variables() {
        return {
          fullPath: this.fullPath,
        };
      },
      update(data) {
        return data.workspace?.workItemTypes?.nodes;
      },
      skip() {
        return !this.canUpdate;
      },
    },
  },
  computed: {
    i18n() {
      return {
        deleteWorkItem: sprintfWorkItem(I18N_WORK_ITEM_DELETE, this.workItemType),
        areYouSureDelete: sprintfWorkItem(I18N_WORK_ITEM_ARE_YOU_SURE_DELETE, this.workItemType),
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
    canLockWorkItem() {
      return this.canUpdate && this.glFeatures.workItemsBeta;
    },
    canPromoteToObjective() {
      return this.canUpdate && this.workItemType === WORK_ITEM_TYPE_VALUE_KEY_RESULT;
    },
    confidentialItemText() {
      return this.isConfidential
        ? this.$options.i18n.disableConfidentiality
        : this.$options.i18n.enableConfidentiality;
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
          class="gl-display-flex gl-justify-content-end gl-w-full"
          :data-testid="$options.notificationsToggleFormTestId"
        >
          <template #list-item>
            <gl-toggle
              :value="subscribedToNotifications"
              :label="$options.i18n.notifications"
              class="work-item-notification-toggle"
              label-position="left"
              @change="toggleNotifications($event)"
            />
          </template>
        </gl-disclosure-dropdown-item>
        <gl-dropdown-divider />
      </template>

      <gl-disclosure-dropdown-item
        v-if="canPromoteToObjective"
        :data-testid="$options.promoteActionTestId"
        @action="promoteToObjective"
      >
        <template #list-item>{{ __('Promote to objective') }}</template>
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
        v-if="canUpdate && !isParentConfidential"
        :data-testid="$options.confidentialityTestId"
        @action="handleToggleWorkItemConfidentiality"
      >
        <template #list-item>{{ confidentialItemText }}</template>
      </gl-disclosure-dropdown-item>

      <work-item-state-toggle
        v-if="canUpdate"
        :data-testid="$options.stateToggleTestId"
        :work-item-id="workItemId"
        :work-item-state="workItemState"
        :work-item-type="workItemType"
        show-as-dropdown-item
      />

      <gl-disclosure-dropdown-item
        :data-testid="$options.copyReferenceTestId"
        :data-clipboard-text="workItemReference"
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

      <template v-if="canDelete">
        <gl-dropdown-divider />
        <gl-disclosure-dropdown-item
          :data-testid="$options.deleteActionTestId"
          variant="danger"
          @action="handleDelete"
        >
          <template #list-item>
            <span class="text-danger">{{ i18n.deleteWorkItem }}</span>
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
      {{ i18n.areYouSureDelete }}
    </gl-modal>
  </div>
</template>
