<script>
import { GlDropdown, GlDropdownDivider, GlTooltipDirective } from '@gitlab/ui';
import Api from '~/api';
import { sprintf } from '~/locale';
import { CUSTOM_LEVEL, i18n } from '../constants';
import CustomNotificationsModal from './custom_notifications_modal.vue';
import NotificationsDropdownItem from './notifications_dropdown_item.vue';

export default {
  name: 'NotificationsDropdown',
  components: {
    GlDropdown,
    GlDropdownDivider,
    NotificationsDropdownItem,
    CustomNotificationsModal,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: {
    containerClass: {
      default: '',
    },
    emailsDisabled: {
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
    showLabel: {
      default: false,
    },
    noFlip: {
      default: false,
    },
  },
  data() {
    return {
      selectedNotificationLevel: this.initialNotificationLevel,
      isLoading: false,
      notificationsModalVisible: false,
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
    buttonText() {
      const notificationTitle =
        this.$options.i18n.notificationTitles[this.selectedNotificationLevel] ||
        this.selectedNotificationLevel;

      if (this.showLabel) {
        return notificationTitle;
      }

      return this.emailsDisabled
        ? this.$options.i18n.notificationDescriptions.owner_disabled
        : sprintf(this.$options.i18n.notificationTooltipTitle, {
            notification_title: notificationTitle,
          });
    },
  },
  methods: {
    openNotificationsModal() {
      if (this.isCustomNotification) {
        this.notificationsModalVisible = true;
      }
    },
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
        this.openNotificationsModal();
      } catch (error) {
        this.$toast.show(this.$options.i18n.updateNotificationLevelErrorMessage);
      } finally {
        this.isLoading = false;
      }
    },
  },
  customLevel: CUSTOM_LEVEL,
  i18n,
  modalId: 'custom-notifications-modal',
};
</script>

<template>
  <div :class="containerClass">
    <gl-dropdown
      v-gl-tooltip="{ title: buttonText }"
      data-testid="notification-dropdown"
      :size="buttonSize"
      :icon="buttonIcon"
      :loading="isLoading"
      :disabled="emailsDisabled"
      :split="isCustomNotification"
      :text="buttonText"
      :text-sr-only="!showLabel"
      :no-flip="noFlip"
      :aria-label="__('Notification setting - Custom')"
      @click="openNotificationsModal"
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
    <custom-notifications-modal v-model="notificationsModalVisible" :modal-id="$options.modalId" />
  </div>
</template>
