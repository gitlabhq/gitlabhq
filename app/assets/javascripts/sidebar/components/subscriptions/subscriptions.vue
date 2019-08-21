<script>
import { __ } from '~/locale';
import icon from '~/vue_shared/components/icon.vue';
import toggleButton from '~/vue_shared/components/toggle_button.vue';
import tooltip from '~/vue_shared/directives/tooltip';
import eventHub from '../../event_hub';
import { trackEvent } from 'ee_else_ce/event_tracking/issue_sidebar';

const ICON_ON = 'notifications';
const ICON_OFF = 'notifications-off';
const LABEL_ON = __('Notifications on');
const LABEL_OFF = __('Notifications off');

export default {
  directives: {
    tooltip,
  },
  components: {
    icon,
    toggleButton,
  },
  props: {
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    subscribed: {
      type: Boolean,
      required: false,
      default: null,
    },
    id: {
      type: Number,
      required: false,
      default: null,
    },
  },
  computed: {
    showLoadingState() {
      return this.subscribed === null;
    },
    notificationIcon() {
      return this.subscribed ? ICON_ON : ICON_OFF;
    },
    notificationTooltip() {
      return this.subscribed ? LABEL_ON : LABEL_OFF;
    },
  },
  methods: {
    /**
     * We need to emit this event on both component & eventHub
     * for 2 dependencies;
     *
     * 1. eventHub: This component is used in Issue Boards sidebar
     *              where component template is part of HAML
     *              and event listeners are tied to app's eventHub.
     * 2. Component: This compone is also used in Epics in EE
     *               where listeners are tied to component event.
     */
    toggleSubscription() {
      // App's eventHub event emission.
      eventHub.$emit('toggleSubscription', this.id);

      // Component event emission.
      this.$emit('toggleSubscription', this.id);

      trackEvent('toggle_button', 'notifications', this.subscribed ? 0 : 1);
    },
    onClickCollapsedIcon() {
      this.$emit('toggleSidebar');
    },
  },
};
</script>

<template>
  <div>
    <span
      v-tooltip
      class="sidebar-collapsed-icon"
      :title="notificationTooltip"
      data-container="body"
      data-placement="left"
      data-boundary="viewport"
      @click="onClickCollapsedIcon"
    >
      <icon
        :name="notificationIcon"
        :size="16"
        aria-hidden="true"
        class="sidebar-item-icon is-active"
      />
    </span>
    <span class="issuable-header-text hide-collapsed float-left"> {{ __('Notifications') }} </span>
    <toggle-button
      ref="toggleButton"
      :is-loading="showLoadingState"
      :value="subscribed"
      class="float-right hide-collapsed js-issuable-subscribe-button"
      @change="toggleSubscription"
    />
  </div>
</template>
