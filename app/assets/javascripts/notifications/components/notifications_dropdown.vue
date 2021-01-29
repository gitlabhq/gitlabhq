<script>
import {
  GlButtonGroup,
  GlButton,
  GlDropdown,
  GlDropdownDivider,
  GlTooltipDirective,
} from '@gitlab/ui';
import { sprintf } from '~/locale';
import Api from '~/api';
import NotificationsDropdownItem from './notifications_dropdown_item.vue';
import { CUSTOM_LEVEL, i18n } from '../constants';

export default {
  name: 'NotificationsDropdown',
  components: {
    GlButtonGroup,
    GlButton,
    GlDropdown,
    GlDropdownDivider,
    NotificationsDropdownItem,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: {
    containerClass: {
      default: '',
    },
    disabled: {
      default: false,
    },
    dropdownItems: {
      default: [],
    },
    buttonSize: {
      default: 'medium',
    },
    initialNotificationLevel: {
      default: '',
    },
    projectId: {
      default: null,
    },
    groupId: {
      default: null,
    },
  },
  data() {
    return {
      selectedNotificationLevel: this.initialNotificationLevel,
      isLoading: false,
    };
  },
  computed: {
    notificationLevels() {
      return this.dropdownItems.map((level) => ({
        level,
        title: this.$options.i18n.notificationTitles[level] || '',
        description: this.$options.i18n.notificationDescriptions[level] || '',
      }));
    },
    isCustomNotification() {
      return this.selectedNotificationLevel === CUSTOM_LEVEL;
    },
    buttonIcon() {
      if (this.isLoading) {
        return null;
      }

      return this.selectedNotificationLevel === 'disabled' ? 'notifications-off' : 'notifications';
    },
    buttonTooltip() {
      const notificationTitle =
        this.$options.i18n.notificationTitles[this.selectedNotificationLevel] ||
        this.selectedNotificationLevel;

      return this.disabled
        ? this.$options.i18n.notificationDescriptions.owner_disabled
        : sprintf(this.$options.i18n.notificationTooltipTitle, {
            notification_title: notificationTitle,
          });
    },
  },
  methods: {
    selectItem(level) {
      if (level !== this.selectedNotificationLevel) {
        this.updateNotificationLevel(level);
      }
    },
    async updateNotificationLevel(level) {
      this.isLoading = true;

      try {
        await Api.updateNotificationSettings(this.projectId, this.groupId, { level });
        this.selectedNotificationLevel = level;
      } catch (error) {
        this.$toast.show(this.$options.i18n.updateNotificationLevelErrorMessage, { type: 'error' });
      } finally {
        this.isLoading = false;
      }
    },
  },
  customLevel: CUSTOM_LEVEL,
  i18n,
};
</script>

<template>
  <div :class="containerClass">
    <gl-button-group
      v-if="isCustomNotification"
      v-gl-tooltip="{ title: buttonTooltip }"
      data-testid="notificationButton"
      :size="buttonSize"
    >
      <gl-button :size="buttonSize" :icon="buttonIcon" :loading="isLoading" :disabled="disabled" />
      <gl-dropdown :size="buttonSize" :disabled="disabled">
        <notifications-dropdown-item
          v-for="item in notificationLevels"
          :key="item.level"
          :level="item.level"
          :title="item.title"
          :description="item.description"
          :notification-level="selectedNotificationLevel"
          @item-selected="selectItem"
        />
        <gl-dropdown-divider />
        <notifications-dropdown-item
          :key="$options.customLevel"
          :level="$options.customLevel"
          :title="$options.i18n.notificationTitles.custom"
          :description="$options.i18n.notificationDescriptions.custom"
          :notification-level="selectedNotificationLevel"
          @item-selected="selectItem"
        />
      </gl-dropdown>
    </gl-button-group>

    <gl-dropdown
      v-else
      v-gl-tooltip="{ title: buttonTooltip }"
      data-testid="notificationButton"
      :icon="buttonIcon"
      :loading="isLoading"
      :size="buttonSize"
      :disabled="disabled"
    >
      <notifications-dropdown-item
        v-for="item in notificationLevels"
        :key="item.level"
        :level="item.level"
        :title="item.title"
        :description="item.description"
        :notification-level="selectedNotificationLevel"
        @item-selected="selectItem"
      />
      <gl-dropdown-divider />
      <notifications-dropdown-item
        :key="$options.customLevel"
        :level="$options.customLevel"
        :title="$options.i18n.notificationTitles.custom"
        :description="$options.i18n.notificationDescriptions.custom"
        :notification-level="selectedNotificationLevel"
        @item-selected="selectItem"
      />
    </gl-dropdown>
  </div>
</template>
