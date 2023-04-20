<script>
import {
  GlDropdown,
  GlDropdownItem,
  GlDropdownForm,
  GlDropdownDivider,
  GlModal,
  GlModalDirective,
  GlToggle,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import toast from '~/vue_shared/plugins/global_toast';
import { isLoggedIn } from '~/lib/utils/common_utils';
import {
  sprintfWorkItem,
  I18N_WORK_ITEM_DELETE,
  I18N_WORK_ITEM_ARE_YOU_SURE_DELETE,
  TEST_ID_CONFIDENTIALITY_TOGGLE_ACTION,
  TEST_ID_NOTIFICATIONS_TOGGLE_ACTION,
  TEST_ID_NOTIFICATIONS_TOGGLE_FORM,
  TEST_ID_DELETE_ACTION,
  WIDGET_TYPE_NOTIFICATIONS,
} from '../constants';
import updateWorkItemNotificationsMutation from '../graphql/update_work_item_notifications.mutation.graphql';

export default {
  i18n: {
    enableTaskConfidentiality: s__('WorkItem|Turn on confidentiality'),
    disableTaskConfidentiality: s__('WorkItem|Turn off confidentiality'),
    notifications: s__('WorkItem|Notifications'),
    notificationOn: s__('WorkItem|Notifications turned on.'),
    notificationOff: s__('WorkItem|Notifications turned off.'),
  },
  components: {
    GlDropdown,
    GlDropdownItem,
    GlDropdownForm,
    GlDropdownDivider,
    GlModal,
    GlToggle,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  mixins: [Tracking.mixin({ label: 'actions_menu' })],
  isLoggedIn: isLoggedIn(),
  notificationsToggleTestId: TEST_ID_NOTIFICATIONS_TOGGLE_ACTION,
  notificationsToggleFormTestId: TEST_ID_NOTIFICATIONS_TOGGLE_FORM,
  confidentialityTestId: TEST_ID_CONFIDENTIALITY_TOGGLE_ACTION,
  deleteActionTestId: TEST_ID_DELETE_ACTION,
  props: {
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
  },
  data() {
    return {
      initialSubscribed: this.subscribedToNotifications,
    };
  },
  computed: {
    i18n() {
      return {
        deleteWorkItem: sprintfWorkItem(I18N_WORK_ITEM_DELETE, this.workItemType),
        areYouSureDelete: sprintfWorkItem(I18N_WORK_ITEM_ARE_YOU_SURE_DELETE, this.workItemType),
      };
    },
  },
  watch: {
    subscribedToNotifications() {
      /**
       * To toggle the value if mutation fails, assign the
       * subscribedToNotifications boolean value directly
       * to data prop.
       */
      this.initialSubscribed = this.subscribedToNotifications;
    },
  },
  methods: {
    handleToggleWorkItemConfidentiality() {
      this.track('click_toggle_work_item_confidentiality');
      this.$emit('toggleWorkItemConfidentiality', !this.isConfidential);
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
      const inputVariables = {
        id: this.workItemId,
        notificationsWidget: {
          subscribed,
        },
      };
      this.$apollo
        .mutate({
          mutation: updateWorkItemNotificationsMutation,
          variables: {
            input: inputVariables,
          },
          optimisticResponse: {
            workItemUpdate: {
              errors: [],
              workItem: {
                id: this.workItemId,
                widgets: [
                  {
                    type: WIDGET_TYPE_NOTIFICATIONS,
                    subscribed,
                    __typename: 'WorkItemWidgetNotifications',
                  },
                ],
                __typename: 'WorkItem',
              },
              __typename: 'WorkItemUpdatePayload',
            },
          },
        })
        .then(
          ({
            data: {
              workItemUpdate: { errors },
            },
          }) => {
            if (errors?.length) {
              throw new Error(errors[0]);
            }
            toast(
              subscribed ? this.$options.i18n.notificationOn : this.$options.i18n.notificationOff,
            );
          },
        )
        .catch((error) => {
          this.updateError = error.message;
          this.$emit('error', error.message);
        });
    },
  },
};
</script>

<template>
  <div>
    <gl-dropdown
      icon="ellipsis_v"
      data-testid="work-item-actions-dropdown"
      text-sr-only
      :text="__('More actions')"
      category="tertiary"
      no-caret
      right
    >
      <template v-if="$options.isLoggedIn">
        <gl-dropdown-form
          class="work-item-notifications-form"
          :data-testid="$options.notificationsToggleFormTestId"
        >
          <div class="gl-px-5 gl-pb-2 gl-pt-1">
            <gl-toggle
              v-model="initialSubscribed"
              :label="$options.i18n.notifications"
              :data-testid="$options.notificationsToggleTestId"
              label-position="left"
              label-id="notifications-toggle"
              @change="toggleNotifications($event)"
            />
          </div>
        </gl-dropdown-form>
        <gl-dropdown-divider />
      </template>
      <template v-if="canUpdate && !isParentConfidential">
        <gl-dropdown-item
          :data-testid="$options.confidentialityTestId"
          @click="handleToggleWorkItemConfidentiality"
          >{{
            isConfidential
              ? $options.i18n.disableTaskConfidentiality
              : $options.i18n.enableTaskConfidentiality
          }}</gl-dropdown-item
        >
        <gl-dropdown-divider v-if="canDelete" />
      </template>
      <gl-dropdown-item
        v-if="canDelete"
        v-gl-modal="'work-item-confirm-delete'"
        :data-testid="$options.deleteActionTestId"
        variant="danger"
        >{{ i18n.deleteWorkItem }}</gl-dropdown-item
      >
    </gl-dropdown>
    <gl-modal
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
