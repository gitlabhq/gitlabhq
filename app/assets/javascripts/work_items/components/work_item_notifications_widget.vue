<script>
import { GlButton, GlIcon, GlTooltipDirective } from '@gitlab/ui';

import * as Sentry from '~/sentry/sentry_browser_wrapper';

import { __, s__ } from '~/locale';
import toast from '~/vue_shared/plugins/global_toast';
import { isLoggedIn } from '~/lib/utils/common_utils';

import getWorkItemNotificationsByIdQuery from '../graphql/get_work_item_notifications_by_id.query.graphql';
import updateWorkItemNotificationsMutation from '../graphql/update_work_item_notifications.mutation.graphql';

import { WIDGET_TYPE_NOTIFICATIONS } from '../constants';

const ICON_ON = 'notifications';
const ICON_OFF = 'notifications-off';

export default {
  i18n: {
    notificationOn: s__('WorkItem|Notifications turned on.'),
    notificationOff: s__('WorkItem|Notifications turned off.'),
    labelOn: __('Notifications on'),
    labelOff: __('Notifications off'),
  },
  components: {
    GlButton,
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    workItemId: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      workItemNotificationsSubscribed: false,
    };
  },
  apollo: {
    workItemNotificationsSubscribed: {
      query: () => {
        return getWorkItemNotificationsByIdQuery;
      },
      variables() {
        return {
          id: this.workItemId,
        };
      },
      skip() {
        return !this.workItemId;
      },
      update(data) {
        return Boolean(
          data?.workItem?.widgets?.find((widget) => widget.type === WIDGET_TYPE_NOTIFICATIONS)
            ?.subscribed,
        );
      },
      error(error) {
        Sentry.captureException(error);
      },
    },
  },
  computed: {
    notificationTooltip() {
      return this.workItemNotificationsSubscribed
        ? this.$options.i18n.labelOn
        : this.$options.i18n.labelOff;
    },
    notificationIcon() {
      return this.workItemNotificationsSubscribed ? ICON_ON : ICON_OFF;
    },
    isLoggedIn() {
      return isLoggedIn();
    },
  },
  methods: {
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
          optimisticResponse: {
            workItemSubscribe: {
              errors: [],
              workItem: {
                __typename: 'WorkItem',
                id: this.workItemId,
                widgets: [
                  {
                    type: WIDGET_TYPE_NOTIFICATIONS,
                    subscribed,
                    __typename: 'WorkItemWidgetNotifications',
                  },
                ],
              },
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
  },
};
</script>

<template>
  <gl-button
    v-if="isLoggedIn"
    ref="tooltip"
    v-gl-tooltip.hover
    category="secondary"
    data-testid="subscribe-button"
    :data-subscribed="workItemNotificationsSubscribed ? 'true' : 'false'"
    :title="notificationTooltip"
    class="btn-icon"
    @click="toggleNotifications(!workItemNotificationsSubscribed)"
  >
    <gl-icon
      :name="notificationIcon"
      :size="16"
      :class="{ '!gl-text-status-info': workItemNotificationsSubscribed }"
    />
  </gl-button>
</template>
