<script>
import { GlIcon, GlLoadingIcon, GlToggle, GlTooltipDirective } from '@gitlab/ui';
import createFlash from '~/flash';
import { IssuableType } from '~/issue_show/constants';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { __, sprintf } from '~/locale';
import SidebarEditableItem from '~/sidebar/components/sidebar_editable_item.vue';
import { subscribedQueries } from '~/sidebar/constants';

const ICON_ON = 'notifications';
const ICON_OFF = 'notifications-off';

export default {
  tracking: {
    event: 'click_edit_button',
    label: 'right_sidebar',
    property: 'subscriptions',
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlIcon,
    GlLoadingIcon,
    GlToggle,
    SidebarEditableItem,
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
      update(data) {
        return data.workspace?.issuable?.subscribed || false;
      },
      result({ data }) {
        this.emailsDisabled = this.parentIsGroup
          ? data.workspace?.emailsDisabled
          : data.workspace?.issuable?.emailsDisabled;
        this.$emit('subscribedUpdated', data.workspace?.issuable?.subscribed);
      },
      error() {
        createFlash({
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
    isLoading() {
      return this.$apollo.queries?.subscribed?.loading || this.loading;
    },
    notificationTooltip() {
      if (this.emailsDisabled) {
        return this.subscribeDisabledDescription;
      }
      return this.subscribed ? this.$options.i18n.labelOn : this.$options.i18n.labelOff;
    },
    notificationIcon() {
      if (this.emailsDisabled || !this.subscribed) {
        return ICON_OFF;
      }
      return ICON_ON;
    },
    parentIsGroup() {
      return this.issuableType === IssuableType.Epic;
    },
    subscribeDisabledDescription() {
      return sprintf(__('Disabled by %{parent} owner'), {
        parent: this.parentIsGroup ? 'group' : 'project',
      });
    },
    isLoggedIn() {
      return isLoggedIn();
    },
    canSubscribe() {
      return this.emailsDisabled || !this.isLoggedIn;
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
              createFlash({
                message: errors[0],
              });
            }
          },
        )
        .catch(() => {
          createFlash({
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
      this.$emit('expandSidebar');
    },
  },
  i18n: {
    notifications: __('Notifications'),
    labelOn: __('Notifications on'),
    labelOff: __('Notifications off'),
  },
};
</script>

<template>
  <sidebar-editable-item
    ref="editable"
    :title="$options.i18n.notifications"
    :tracking="$options.tracking"
    :loading="isLoading"
    :can-edit="false"
    class="block subscriptions"
  >
    <template #collapsed-right>
      <gl-toggle
        :value="subscribed"
        :is-loading="isLoading"
        :disabled="canSubscribe"
        class="hide-collapsed gl-ml-auto"
        data-testid="subscription-toggle"
        :label="$options.i18n.notifications"
        label-position="hidden"
        @change="setSubscribed"
      />
    </template>
    <template #collapsed>
      <span
        ref="tooltip"
        v-gl-tooltip.viewport.left
        :title="notificationTooltip"
        class="sidebar-collapsed-icon"
        @click="toggleSubscribed"
      >
        <gl-loading-icon v-if="isLoading" size="sm" class="sidebar-item-icon is-active" />
        <gl-icon v-else :name="notificationIcon" :size="16" class="sidebar-item-icon is-active" />
      </span>
      <div v-show="emailsDisabled" class="gl-mt-3 hide-collapsed gl-text-gray-500">
        {{ subscribeDisabledDescription }}
      </div>
    </template>
    <template #default> </template>
  </sidebar-editable-item>
</template>
