<script>
import { GlButton, GlIcon, GlTooltipDirective } from '@gitlab/ui';

import * as Sentry from '~/sentry/sentry_browser_wrapper';

import { __, s__ } from '~/locale';
import toast from '~/vue_shared/plugins/global_toast';
import { isLoggedIn } from '~/lib/utils/common_utils';

import updateWorkItemNotificationsMutation from '../graphql/update_work_item_notifications.mutation.graphql';

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
  isLoggedIn: isLoggedIn(),
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    workItemId: {
      type: String,
      required: false,
      default: null,
    },
    canUpdate: {
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
      isLockDiscussionUpdating: false,
      emailsDisabled: false,
    };
  },
  computed: {
    notificationTooltip() {
      return this.subscribedToNotifications
        ? this.$options.i18n.labelOn
        : this.$options.i18n.labelOff;
    },
    notificationIcon() {
      return this.subscribedToNotifications ? ICON_ON : ICON_OFF;
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
    ref="tooltip"
    v-gl-tooltip.hover
    category="secondary"
    data-testid="subscribe-button"
    :title="notificationTooltip"
    class="btn-icon"
    @click="toggleNotifications(!subscribedToNotifications)"
  >
    <gl-icon
      :name="notificationIcon"
      :size="16"
      :class="{ '!gl-fill-blue-500': subscribedToNotifications }"
    />
  </gl-button>
</template>
