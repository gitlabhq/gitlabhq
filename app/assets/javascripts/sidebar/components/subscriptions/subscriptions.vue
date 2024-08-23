<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlIcon, GlToggle, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import Tracking from '~/tracking';
import eventHub from '../../event_hub';

const ICON_ON = 'notifications';
const ICON_OFF = 'notifications-off';
const LABEL_ON = __('Notifications on');
const LABEL_OFF = __('Notifications off');

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlIcon,
    GlToggle,
  },
  mixins: [Tracking.mixin({ label: 'right_sidebar' })],
  props: {
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    projectEmailsEnabled: {
      type: Boolean,
      required: false,
      default: true,
    },
    subscribeDisabledDescription: {
      type: String,
      required: false,
      default: '',
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
    tracking() {
      return {
        // eslint-disable-next-line no-underscore-dangle
        category: this.$options._componentTag,
      };
    },
    showLoadingState() {
      return this.subscribed === null;
    },
    notificationIcon() {
      if (!this.projectEmailsEnabled) {
        return ICON_OFF;
      }
      return this.subscribed ? ICON_ON : ICON_OFF;
    },
    notificationTooltip() {
      if (!this.projectEmailsEnabled) {
        return this.subscribeDisabledDescription;
      }
      return this.subscribed ? LABEL_ON : LABEL_OFF;
    },
    notificationText() {
      if (!this.projectEmailsEnabled) {
        return this.subscribeDisabledDescription;
      }
      return __('Notifications');
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

      this.track('toggle_button', {
        property: 'notifications',
        value: this.subscribed ? 0 : 1,
      });
    },
    onClickCollapsedIcon() {
      this.$emit('toggleSidebar');
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-justify-between">
    <span
      ref="tooltip"
      v-gl-tooltip.viewport.left
      :title="notificationTooltip"
      class="sidebar-collapsed-icon"
      @click="onClickCollapsedIcon"
    >
      <gl-icon :name="notificationIcon" :size="16" class="sidebar-item-icon is-active" />
    </span>
    <span class="hide-collapsed" data-testid="subscription-title"> {{ notificationText }} </span>
    <gl-toggle
      v-if="projectEmailsEnabled"
      :is-loading="showLoadingState"
      :value="subscribed"
      class="hide-collapsed"
      data-testid="subscription-toggle"
      :label="__('Notifications')"
      label-position="hidden"
      @change="toggleSubscription"
    />
  </div>
</template>
