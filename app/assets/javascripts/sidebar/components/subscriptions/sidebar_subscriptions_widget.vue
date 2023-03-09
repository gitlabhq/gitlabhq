<script>
import { GlDropdownForm, GlIcon, GlLoadingIcon, GlToggle, GlTooltipDirective } from '@gitlab/ui';
import { createAlert } from '~/alert';
import {
  TYPE_EPIC,
  TYPE_MERGE_REQUEST,
  WORKSPACE_GROUP,
  WORKSPACE_PROJECT,
} from '~/issues/constants';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { __, sprintf } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import toast from '~/vue_shared/plugins/global_toast';
import { subscribedQueries, Tracking } from '../../constants';
import SidebarEditableItem from '../sidebar_editable_item.vue';

const ICON_ON = 'notifications';
const ICON_OFF = 'notifications-off';

export default {
  tracking: {
    event: Tracking.editEvent,
    label: Tracking.rightSidebarLabel,
    property: 'subscriptions',
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlDropdownForm,
    GlIcon,
    GlLoadingIcon,
    GlToggle,
    SidebarEditableItem,
  },
  mixins: [glFeatureFlagMixin()],
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
        if (!data) {
          return;
        }
        this.emailsDisabled = this.parentIsGroup
          ? data.workspace?.emailsDisabled
          : data.workspace?.issuable?.emailsDisabled;
        this.$emit('subscribedUpdated', data.workspace?.issuable?.subscribed);
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
    isMergeRequest() {
      return this.issuableType === TYPE_MERGE_REQUEST && this.glFeatures.movedMrSidebar;
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
    notificationIcon() {
      if (this.emailsDisabled || !this.subscribed) {
        return ICON_OFF;
      }
      return ICON_ON;
    },
    parentIsGroup() {
      return this.issuableType === TYPE_EPIC;
    },
    subscribeDisabledDescription() {
      return sprintf(__('Disabled by %{parent} owner'), {
        parent: this.parentIsGroup ? WORKSPACE_GROUP : WORKSPACE_PROJECT,
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
              createAlert({
                message: errors[0],
              });
            }

            if (this.isMergeRequest) {
              toast(subscribed ? __('Notifications turned on.') : __('Notifications turned off.'));
            }
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
  <gl-dropdown-form v-if="isMergeRequest" class="gl-dropdown-item">
    <div class="gl-px-5 gl-pb-2 gl-pt-1">
      <gl-toggle
        :value="subscribed"
        :label="__('Notifications')"
        class="merge-request-notification-toggle"
        label-position="left"
        data-testid="notifications-toggle"
        @change="toggleSubscribed"
      />
    </div>
  </gl-dropdown-form>
  <sidebar-editable-item
    v-else
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
