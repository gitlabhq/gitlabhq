<script>
import { GlButton, GlAnimatedNotificationIcon, GlTooltipDirective } from '@gitlab/ui';

import * as Sentry from '~/sentry/sentry_browser_wrapper';

import { __, s__ } from '~/locale';
import toast from '~/vue_shared/plugins/global_toast';
import { isLoggedIn } from '~/lib/utils/common_utils';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

import getWorkItemNotificationsByIdQuery from '../graphql/get_work_item_notifications_by_id.query.graphql';
import updateWorkItemNotificationsMutation from '../graphql/update_work_item_notifications.mutation.graphql';
import { WIDGET_TYPE_NOTIFICATIONS } from '../constants';
import { findNotificationsWidget } from '../utils';

export default {
  name: 'WorkItemNotificationsWidget',
  i18n: {
    notificationOn: s__('WorkItem|Notifications turned on.'),
    notificationOff: s__('WorkItem|Notifications turned off.'),
    labelOn: __('Notifications are on'),
    labelOff: __('Notifications are off'),
  },
  components: {
    GlButton,
    GlAnimatedNotificationIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    workItemId: {
      type: String,
      required: false,
      default: null,
    },
  },
  emits: ['error'],
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
          useWorkItemFeatures: Boolean(this.glFeatures?.workItemFeaturesField),
        };
      },
      skip() {
        return !this.workItemId;
      },
      update(data) {
        return Boolean(findNotificationsWidget(data?.workItem)?.subscribed);
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
    isLoggedIn() {
      return isLoggedIn();
    },
    workItemNotificationsSubscribedStateText() {
      return this.workItemNotificationsSubscribed ? 'true' : 'false';
    },
  },
  methods: {
    toggleNotifications(subscribed) {
      const notificationWidget = {
        type: WIDGET_TYPE_NOTIFICATIONS,
        subscribed,
        __typename: 'WorkItemWidgetNotifications',
      };

      this.$apollo
        .mutate({
          mutation: updateWorkItemNotificationsMutation,
          variables: {
            input: {
              id: this.workItemId,
              subscribed,
            },
            useWorkItemFeatures: Boolean(this.glFeatures?.workItemFeaturesField),
          },
          optimisticResponse: {
            workItemSubscribe: {
              errors: [],
              workItem: {
                __typename: 'WorkItem',
                id: this.workItemId,
                ...(this.glFeatures?.workItemFeaturesField
                  ? {
                      features: {
                        __typename: 'WorkItemFeatures',
                        notifications: notificationWidget,
                      },
                    }
                  : { widgets: [notificationWidget] }),
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
    v-gl-tooltip.bottom="notificationTooltip"
    category="tertiary"
    size="small"
    :selected="workItemNotificationsSubscribed"
    data-testid="subscribe-button"
    :data-subscribed="workItemNotificationsSubscribedStateText"
    :aria-label="notificationTooltip"
    :aria-pressed="workItemNotificationsSubscribedStateText"
    class="btn-icon"
    @click="toggleNotifications(!workItemNotificationsSubscribed)"
  >
    <gl-animated-notification-icon
      :is-on="!workItemNotificationsSubscribed"
      class="gl-button-icon"
    />
  </gl-button>
</template>
