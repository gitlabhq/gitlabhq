<script>
import { GlButton, GlTooltipDirective, GlAnimatedNotificationIcon } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { TYPE_ISSUE, TYPE_EPIC, NAMESPACE_GROUP, NAMESPACE_PROJECT } from '~/issues/constants';
import { __, sprintf } from '~/locale';
import toast from '~/vue_shared/plugins/global_toast';
import { subscribedQueries } from '../../queries/constants';

export default {
  name: 'SidebarSubscriptionsWidget',
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlButton,
    GlAnimatedNotificationIcon,
  },
  props: {
    iid: {
      type: String,
      required: true,
    },
    fullPath: {
      type: String,
      required: true,
    },
    issuableType: {
      required: true,
      type: String,
    },
  },
  emits: ['expand-sidebar'],
  data() {
    return {
      subscribed: false,
      loading: false,
      emailsDisabled: false,
    };
  },
  apollo: {
    subscribed: {
      query() {
        return subscribedQueries[this.issuableType].query;
      },
      variables() {
        return {
          fullPath: this.fullPath,
          iid: String(this.iid),
        };
      },
      skip() {
        return !this.iid;
      },
      update(data) {
        return data.namespace?.issuable?.subscribed || false;
      },
      result({ data }) {
        if (!data) {
          return;
        }
        this.emailsDisabled = this.parentIsGroup
          ? data.namespace?.emailsDisabled
          : data.namespace?.issuable?.emailsDisabled;
      },
      error() {
        createAlert({
          message: sprintf(
            __('Something went wrong while setting %{issuableType} notifications.'),
            {
              issuableType: this.issuableType,
            },
          ),
        });
      },
    },
  },
  computed: {
    isIssuable() {
      return this.issuableType === TYPE_ISSUE;
    },
    isLoading() {
      return this.$apollo.queries?.subscribed?.loading || this.loading;
    },
    notificationTooltip() {
      if (this.emailsDisabled) {
        return this.subscribeDisabledDescription;
      }
      return this.subscribed ? this.$options.i18n.labelOn : this.$options.i18n.labelOff;
    },
    parentIsGroup() {
      return this.issuableType === TYPE_EPIC;
    },
    subscribeDisabledDescription() {
      return sprintf(__('Disabled by %{parent} owner'), {
        parent: this.parentIsGroup ? NAMESPACE_GROUP : NAMESPACE_PROJECT,
      });
    },
    isMergeRequest() {
      return this.issuableType === 'merge_request';
    },
    subscribedStateText() {
      return this.subscribed ? 'true' : 'false';
    },
  },
  methods: {
    setSubscribed(subscribed) {
      this.loading = true;
      this.$apollo
        .mutate({
          mutation: subscribedQueries[this.issuableType].mutation,
          variables: {
            fullPath: this.fullPath,
            iid: this.iid,
            subscribedState: subscribed,
          },
        })
        .then(
          ({
            data: {
              updateIssuableSubscription: { errors },
            },
          }) => {
            if (errors.length) {
              createAlert({
                message: errors[0],
              });
            }

            toast(subscribed ? __('Notifications turned on.') : __('Notifications turned off.'));
          },
        )
        .catch(() => {
          createAlert({
            message: sprintf(
              __('Something went wrong while setting %{issuableType} notifications.'),
              {
                issuableType: this.issuableType,
              },
            ),
          });
        })
        .finally(() => {
          this.loading = false;
        });
    },
    toggleSubscribed() {
      if (this.emailsDisabled) {
        this.expandSidebar();
      } else {
        this.setSubscribed(!this.subscribed);
      }
    },
    expandSidebar() {
      this.$emit('expand-sidebar');
    },
  },
  i18n: {
    labelOn: __('Notifications are on'),
    labelOff: __('Notifications are off'),
  },
};
</script>

<template>
  <div :class="{ 'inline-block': !isMergeRequest }">
    <gl-button
      ref="tooltip"
      v-gl-tooltip.hover.top
      category="secondary"
      data-testid="subscribe-button"
      class="hide-collapsed btn-icon !gl-align-top"
      :title="notificationTooltip"
      :aria-pressed="subscribedStateText"
      :selected="subscribed"
      :disabled="isLoading"
      :class="{ 'gl-ml-2': isIssuable }"
      @click="toggleSubscribed"
    >
      <gl-animated-notification-icon :is-on="!subscribed" class="gl-button-icon" />
    </gl-button>
    <gl-button
      v-if="!isMergeRequest"
      ref="tooltip"
      v-gl-tooltip.left.viewport
      category="tertiary"
      data-testid="subscribe-button"
      :title="notificationTooltip"
      :aria-pressed="subscribedStateText"
      class="sidebar-collapsed-icon sidebar-collapsed-container !gl-rounded-none !gl-border-0"
      @click="toggleSubscribed"
    >
      <gl-animated-notification-icon :is-on="!subscribed" class="gl-button-icon" />
    </gl-button>
  </div>
</template>
